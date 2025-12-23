@echo off
:: =========================================================
::  RENDER ENGINE (Header, Grid, Footer)
:: =========================================================

cls
echo.
echo  !Bold!!Cyan!======================================================================================================================!Reset!
echo                               !Bold!!Bg_Green!!Hi_White! IT GROCERIES SHOP - Ultimate EDITION !Reset! !Bg_Magenta!!Hi_Yellow!(v21.0 ^| 2025-12-24)!Reset!
echo  !Bold!!Cyan!======================================================================================================================!Reset!
echo.

:: [HEADERS]
echo    !Bold!!Hi_Yellow![ BROWSERS ]                                              [ MULTIMEDIA ^& OFFICE ]!Reset!
for /L %%i in (1,1,5) do ( call :DRAW_ROW %%i )

echo.
echo    !Bold!!Hi_Yellow![ COMMUNICATION ]                                         [ UTILITIES ^& TOOLS ]!Reset!
for /L %%i in (6,1,10) do ( call :DRAW_ROW %%i )

echo.
echo  !Bold!!Cyan!======================================================================================================================!Reset!
echo   !Bold!!Bg_Green!!Hi_White! S !Reset! !Bold!!Hi_Green!Start!Reset!       !Bold!!Bg_Blue!!Hi_White! R !Reset! !White!Refresh!Reset!       !Bold!!Bg_White!!Black! C !Reset! !White!Clear!Reset!        !Bold!!Bg_Cyan!!Hi_White! M !Reset! !White!More (Pg.1)!Reset!
echo   !Bold!!Bg_Yellow!!Black! P !Reset! !White!Profiles!Reset!    !Bold!!Bg_Magenta!!Hi_White! H !Reset! !White!Help!Reset!          !Bold!!Bg_Magenta!!Hi_White! V !Reset! !White!Visit!Reset!        !Bold!!Bg_Red!!Hi_White! X !Reset! !White!Exit!Reset!
echo.
exit /b

:: =========================================================
::  ROW RENDERING LOGIC (Internal)
:: =========================================================
:DRAW_ROW
set /a "L=%1"
set /a "R=%1+10"
if %L% LSS 10 (set "IDL=0%L%") else (set "IDL=%L%")
if %R% LSS 10 (set "IDR=0%R%") else (set "IDR=%R%")

:: Resolve Slot Keys
set "KeyL=" & set "KeyR="
call set "KeyL=%%SLOT_!IDL!%%"
call set "KeyR=%%SLOT_!IDR!%%"

:: --- LEFT COLUMN ---
set "NameL=--- Empty ---" & set "StL=        " & set "ClrL=!Hi_White!" & set "ArchL=     "
if defined KeyL (
    call set "RawName=%%Name_!KeyL!%%"
    set "NameL=!RawName!"
    call set "CheckP64=%%P64_!KeyL!%%"
    call set "CheckP32=%%P32_!KeyL!%%"
    
    set "StL=   OFF  " & set "ClrL=!Bg_Yellow!!Hi_White!"
    if exist "!CheckP64!" ( set "StL= INSTLD " & set "ClrL=!Bg_Cyan!!Hi_White!" & set "ArchL=!Hi_Yellow!(x64)!Reset!" )
    if exist "!CheckP32!" ( set "StL= INSTLD " & set "ClrL=!Bg_Cyan!!Hi_White!" & set "ArchL=!Hi_Yellow!(x86)!Reset!" )
    
    :: CHECK TOGGLE STATUS (ใช้ !sw_XX! ตรงๆ เพราะอยู่ใน environment เดียวกัน)
    if "!sw_%IDL%!"=="1" ( set "StL=   ON   " & set "ClrL=!Bg_Magenta!!Black!" )
    if "!done_%IDL%!"=="1" ( set "StL=  DONE  " & set "ClrL=!Bg_Green!!Hi_White!" )
)
set "NameL=!NameL!                         "
set "NameL=!NameL:~0,25!"

:: --- RIGHT COLUMN ---
set "NameR=--- Empty ---" & set "StR=        " & set "ClrR=!Hi_White!" & set "ArchR=     "
if defined KeyR (
    call set "RawName=%%Name_!KeyR!%%"
    set "NameR=!RawName!"
    call set "CheckP64=%%P64_!KeyR!%%"
    call set "CheckP32=%%P32_!KeyR!%%"
    
    set "StR=   OFF  " & set "ClrR=!Bg_Yellow!!Hi_White!"
    if exist "!CheckP64!" ( set "StR= INSTLD " & set "ClrR=!Bg_Cyan!!Hi_White!" & set "ArchR=!Hi_Yellow!(x64)!Reset!" )
    if exist "!CheckP32!" ( set "StR= INSTLD " & set "ClrR=!Bg_Cyan!!Hi_White!" & set "ArchR=!Hi_Yellow!(x86)!Reset!" )
    
    :: CHECK TOGGLE STATUS
    if "!sw_%IDR%!"=="1" ( set "StR=   ON   " & set "ClrR=!Bg_Magenta!!Black!" )
    if "!done_%IDR%!"=="1" ( set "StR=  DONE  " & set "ClrR=!Bg_Green!!Hi_White!" )
)
set "NameR=!NameR!                         "
set "NameR=!NameR:~0,25!"

echo    !Hi_Cyan![!IDL!]!Reset! !ClrL! !NameL! [!StL!]!Reset! !ArchL!      !Hi_Cyan![!IDR!]!Reset! !ClrR! !NameR! [!StR!]!Reset! !ArchR!
exit /b
