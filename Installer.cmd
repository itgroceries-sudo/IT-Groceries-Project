@echo off
setlocal EnableDelayedExpansion

REM ========================================================= 
REM  IT GROCERIES SHOP - ULTIMATE INSTALLER (v20.5)
REM  Fixes: Loop Variable Expansion (The Silent Skip Bug)
REM =========================================================

set "BASE_DIR=%~dp0"
if "%BASE_DIR:~-1%"=="\" set "BASE_DIR=%BASE_DIR:~0,-1%"
set "BIN_DIR=%BASE_DIR%\bin"
set "SCRIPT_DIR=%BASE_DIR%\scripts"
set "DB_FILE=%BASE_DIR%\Database.cmd"
set "THEME_FILE=%BIN_DIR%\Theme.cmd"
set "MENU_FILE=%BIN_DIR%\Menu.cmd"

cd /d "%BASE_DIR%"

if not "%1"=="am_admin" ( powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0' -ArgumentList 'am_admin'" & exit /b )

REM [SYSTEM BRIDGE]
if not exist "%BIN_DIR%\aria2c.exe" ( echo [ERROR] aria2c.exe missing in bin! & pause & exit )
copy /y "%BIN_DIR%\aria2c.exe" "%TEMP%\aria2c.exe" >nul
copy /y "%BIN_DIR%\Master.ps1" "%TEMP%\Master.ps1" >nul

REM [INIT]
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
if exist "%DB_FILE%" ( call "%DB_FILE%" ) else ( echo [ERROR] Database Missing! & pause & exit )
if exist "%THEME_FILE%" ( call "%THEME_FILE%" ) else ( echo [ERROR] Theme Missing! & pause & exit )

title IT Groceries Shop - Ultimate Installer [v20.5]

REM [RESET VARS]
for /L %%n in (1,1,40) do (
    set "n=0%%n" & set "ID=!n:~-2!"
    set "sw_!ID!=0" & set "uw_!ID!=0" & set "done_!ID!=0" & set "failed_!ID!=0"
)

:MAIN_MENU
if exist "%MENU_FILE%" ( call "%MENU_FILE%" ) else ( echo [ERROR] Menu.cmd Missing! & pause & exit )

set "choice="
set /p "choice=!Bold!Select Item [!Bg_Magenta!Pg.1!Reset!] or [!Bold!!Bg_Green! S !Reset! !Bold!!Bg_Blue! R !Reset! !Bold!!Bg_White!!Black! C !Reset! !Bold!!Bg_Cyan! M !Reset! !Bold!!Bg_Yellow! P !Reset!]: !Reset!"

REM [COMMANDS]
if /i "%choice%"=="S" goto :START_PROCESS
if /i "%choice%"=="R" goto :REFRESH_STATUS
if /i "%choice%"=="C" call :CLEAR_ALL & goto :MAIN_MENU
if /i "%choice%"=="X" goto :EXIT_CLEANUP
if /i "%choice%"=="V" start "" "https://www.youtube.com/itgroceries/join" & goto :MAIN_MENU

REM [INPUT VALIDATION]
set /a "chk=%choice%" 2>nul
if %chk% LEQ 0 goto :MAIN_MENU
if %chk% LSS 10 set "chk=0%chk%"
set "choice=%chk:~-2%"
if %choice% GTR 40 goto :MAIN_MENU

call :TOGGLE %choice%
goto :MAIN_MENU

REM =========================================================
REM  LOGIC CONTROLLER
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
for /L %%n in (1,1,40) do ( set "n=0%%n" & set "ID=!n:~-2!" & set "done_!ID!=0" & set "failed_!ID!=0" )
goto :MAIN_MENU

:START_PROCESS
cls
echo. & echo   !Bg_Cyan!!Hi_White![ PROCESS ]!Reset! !Bold!!Cyan!Starting Tasks...!Reset! & echo   ---------------------------------------------------

REM [FIXED LOOP] ใช้ call set เพื่ออ่านค่าตัวแปรที่ซ่อนอยู่ (วิธีนี้ชัวร์ 100%)
for /L %%n in (1,1,40) do (
    set "n=0%%n" & set "ID=!n:~-2!"
    
    REM ดึงค่า sw_XX มาใส่ตัวแปร STATUS
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

echo. & echo   !Bg_Blue!!Hi_White![ FINISHED ]!Reset! !Bold!!Cyan!Queue Processing Complete.!Reset! 
REM รอ 3 วินาที แล้วกลับหน้าเมนูอัตโนมัติ
timeout /t 3 >nul
goto :MAIN_MENU


REM =========================================================
REM  WORKER (SUBROUTINE)
REM =========================================================
:INSTALL_WORKER
set "WorkID=%1"
call set "SoftwareID=%%SLOT_%WorkID%%%"

if "%SoftwareID%"=="" (
    echo   !Bg_Red!!Hi_White![ ERROR ]!Reset! Slot %WorkID% has no ID in Database.
    exit /b
)

echo. & echo   !Bg_Yellow!!Black![ LOCAL ]!Reset! !Hi_Yellow!Installing: !SoftwareID! (ID: %WorkID%)...!Reset!
set "TargetScript=%SCRIPT_DIR%\inst_!SoftwareID!.ps1"

if not exist "!TargetScript!" (
    echo   !Bg_Red!!Hi_White![ ERROR ]!Reset! Script missing: inst_!SoftwareID!.ps1
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $env:UseAria2='1'; & '!TargetScript!' }"

if !errorlevel! EQU 0 ( 
    echo   !Bg_Green!!Hi_White![ OK ]!Reset! Success
    set "done_%WorkID%=1" 
) else ( 
    echo   !Bg_Red!!Hi_White![ FAIL ]!Reset! Error Code: !errorlevel! 
)
exit /b

:EXIT_CLEANUP
if exist "%TEMP%\aria2c.exe" del "%TEMP%\aria2c.exe" >nul
if exist "%TEMP%\Master.ps1" del "%TEMP%\Master.ps1" >nul
exit