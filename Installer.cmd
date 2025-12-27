@echo off
setlocal EnableDelayedExpansion

REM ========================================================= 
REM  IT GROCERIES SHOP - ULTIMATE INSTALLER (v28.0 Path Fix)
REM  Fix: Inject %TEMP% to $env:Path to force Aria2 detection
REM =========================================================

REM [CONFIG]
set "REPO_URL=https://raw.githubusercontent.com/itgroceries-sudo/IT-Groceries-Project/main"

REM [SETUP PATHS] บังคับใช้ %TEMP% เป็นฐานบัญชาการ
set "BASE_DIR=%TEMP%"
cd /d "%BASE_DIR%"

REM กำหนดตำแหน่งไฟล์
set "ARIA2_EXE=%BASE_DIR%\aria2c.exe"
set "MASTER_PS1=%BASE_DIR%\Master.ps1"
set "DB_FILE=%BASE_DIR%\Database.cmd"

REM Theme/Menu ยอมให้อยู่ใน bin ได้
set "THEME_FILE=%BASE_DIR%\bin\Theme.cmd"
set "MENU_FILE=%BASE_DIR%\bin\Menu.cmd"

REM สร้างโฟลเดอร์
if not exist "%BASE_DIR%\bin" mkdir "%BASE_DIR%\bin"
if not exist "%BASE_DIR%\scripts" mkdir "%BASE_DIR%\scripts"

REM [ADMIN CHECK]
if not "%1"=="am_admin" ( powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0' -ArgumentList 'am_admin'" & exit /b )

REM ========================================================= 
REM  PHASE 1: PREPARE ASSETS (MOVE TO ROOT)
REM =========================================================
echo.
echo [INIT] Synchronizing Assets...

REM 1. Aria2c (ย้ายจาก bin -> Root)
if exist "%BASE_DIR%\bin\aria2c.exe" copy /y "%BASE_DIR%\bin\aria2c.exe" "%ARIA2_EXE%" >nul
if not exist "%ARIA2_EXE%" (
    echo    [CLOUD] Fetching Aria2c...
    powershell -Command "Invoke-WebRequest 'https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip' -OutFile 'aria2.zip'; Expand-Archive 'aria2.zip' -Dest 'aria2_extract' -Force; Move-Item 'aria2_extract\aria2-*\aria2c.exe' '%ARIA2_EXE%' -Force; Remove-Item 'aria2.zip', 'aria2_extract' -Recurse -Force"
)

REM 2. Master Engine (ย้ายจาก bin -> Root)
if exist "%BASE_DIR%\bin\Master.ps1" copy /y "%BASE_DIR%\bin\Master.ps1" "%MASTER_PS1%" >nul
if not exist "%MASTER_PS1%" (
    echo    [CLOUD] Fetching Master Engine...
    powershell -Command "Invoke-WebRequest '%REPO_URL%/bin/Master.ps1' -OutFile '%MASTER_PS1%'"
)

REM 3. Database
if not exist "%DB_FILE%" powershell -Command "Invoke-WebRequest '%REPO_URL%/Database.cmd' -OutFile '%DB_FILE%'"

REM 4. Theme & Menu
if not exist "%THEME_FILE%" powershell -Command "Invoke-WebRequest '%REPO_URL%/bin/Theme.cmd' -OutFile '%THEME_FILE%'"
if not exist "%MENU_FILE%" powershell -Command "Invoke-WebRequest '%REPO_URL%/bin/Menu.cmd' -OutFile '%MENU_FILE%'"

REM ========================================================= 
REM  PHASE 2: LOAD UI
REM =========================================================
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"

if exist "%THEME_FILE%" call "%THEME_FILE%"
if exist "%DB_FILE%" ( call "%DB_FILE%" ) else ( echo [CRITICAL] Database Failed. & pause & exit )

title IT Groceries Shop - Cloud Installer [v28.0]

REM [RESET VARS]
for /L %%n in (1,1,40) do (
    set "n=0%%n" & set "ID=!n:~-2!"
    set "sw_!ID!=0" & set "done_!ID!=0"
)

REM ========================================================= 
REM  MAIN CONTROLLER
REM =========================================================
:MAIN_MENU
if exist "%MENU_FILE%" ( call "%MENU_FILE%" ) else ( echo [ERROR] Menu Missing. & pause & exit )

set "choice="
set /p "choice=!Bold!Select Item [!Bg_Magenta!Pg.1!Reset!] or [!Bold!!Bg_Green! S !Reset! !Bold!!Bg_Blue! R !Reset! !Bold!!Bg_White!!Black! C !Reset! !Bold!!Bg_Cyan! M !Reset! !Bold!!Bg_Yellow! P !Reset!]: !Reset!"

if /i "%choice%"=="S" goto :START_PROCESS
if /i "%choice%"=="R" goto :REFRESH_STATUS
if /i "%choice%"=="C" call :CLEAR_ALL & goto :MAIN_MENU
if /i "%choice%"=="X" goto :EXIT_CLEANUP
if /i "%choice%"=="V" start "" "https://www.youtube.com/itgroceries/join" & goto :MAIN_MENU

set /a "chk=%choice%" 2>nul
if %chk% LEQ 0 goto :MAIN_MENU
if %chk% LSS 10 set "chk=0%chk%"
set "choice=%chk:~-2%"
if %choice% GTR 40 goto :MAIN_MENU

call :TOGGLE %choice%
goto :MAIN_MENU

REM =========================================================
REM  LOGIC
REM =========================================================
:TOGGLE
set "TGT=%~1"
call set "CheckSlot=%%SLOT_%TGT%%%"
if "%CheckSlot%"=="" exit /b
set /a "sw_%TGT% = 1 - sw_%TGT%"
exit /b

:CLEAR_ALL
for /L %%n in (1,1,40) do ( set "n=0%%n" & set "ID=!n:~-2!" & set "sw_!ID!=0" )
exit /b

:REFRESH_STATUS
for /L %%n in (1,1,40) do ( set "n=0%%n" & set "ID=!n:~-2!" & set "done_!ID!=0" )
goto :MAIN_MENU

:START_PROCESS
cls
echo. & echo    !Bg_Cyan!!Hi_White![ PROCESS ]!Reset! !Bold!!Cyan!Starting Tasks...!Reset! & echo    ---------------------------------------------------

for /L %%n in (1,1,40) do (
    set "n=0%%n" & set "ID=!n:~-2!"
    set "STATUS="
    call set "STATUS=%%sw_!ID!%%"
    if "!STATUS!"=="1" (
        call :INSTALL_WORKER !ID!
    )
)

REM [FINALIZE]
for /L %%n in (1,1,40) do (
    set "n=0%%n" & set "ID=!n:~-2!"
    set "sw_!ID!=0"
)

echo. & echo    !Bg_Blue!!Hi_White![ FINISHED ]!Reset! !Bold!!Cyan!Queue Processing Complete.!Reset! 
timeout /t 3 >nul
goto :MAIN_MENU

REM =========================================================
REM  WORKER (ENV INJECTION FIX)
REM =========================================================
:INSTALL_WORKER
set "WorkID=%1"
call set "SoftwareID=%%SLOT_%WorkID%%%"
call set "RealName=%%Name_%SoftwareID%%%"

if "%SoftwareID%"=="" exit /b

echo. & echo    !Bg_Yellow!!Black![ LOCAL ]!Reset! !Hi_Yellow!Installing: !RealName! (ID: %WorkID%)...!Reset!

set "TargetScript=%BASE_DIR%\inst_!SoftwareID!.ps1"
set "CloudURL=%REPO_URL%/scripts/inst_!SoftwareID!.ps1"

REM 1. [FETCH] ดาวน์โหลดมาวางที่ Root Temp
if not exist "!TargetScript!" (
    echo    !Bg_Magenta!!Hi_White![ CLOUD ]!Reset! Fetching script from GitHub...
    powershell -Command "try { Invoke-WebRequest -Uri '%CloudURL%' -OutFile '!TargetScript!' -ErrorAction Stop } catch { exit 1 }"
    
    if not exist "!TargetScript!" (
        echo    !Bg_Red!!Hi_White![ ERROR ]!Reset! Download Failed.
        exit /b
    ) else (
        echo    !Bg_Green!!Black![ FOUND ]!Reset! Downloaded successfully.
    )
)

REM 2. [EXECUTE WITH PATH INJECTION]
REM - บรรทัดสำคัญ: $env:Path += ';%BASE_DIR%'
REM - คำสั่งนี้จะบังคับให้ PowerShell รู้จักโฟลเดอร์ Temp ในฐานะ System Path
REM - ทำให้ Master.ps1 หา 'aria2c' เจอแน่นอน (เหมือนพิมพ์ aria2c ใน cmd ได้เลย)

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $ErrorActionPreference = 'Stop'; $env:Path += ';%BASE_DIR%'; $env:UseAria2 = '1'; if (Test-Path '%BASE_DIR%\Master.ps1') { . '%BASE_DIR%\Master.ps1' } else { throw 'Master Missing' }; & '!TargetScript!' }"

if !errorlevel! EQU 0 ( 
    echo    !Bg_Green!!Hi_White![ OK ]!Reset! Success
    set "done_%WorkID%=1" 
) else ( 
    echo    !Bg_Red!!Hi_White![ FAIL ]!Reset! Error Code: !errorlevel! 
)

REM 3. [CLEANUP]
if exist "!TargetScript!" del /f /q "!TargetScript!" >nul
exit /b

:EXIT_CLEANUP
exit