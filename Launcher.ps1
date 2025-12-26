# =========================================================
#  IT Groceries Launcher (v12.0 - The Mother Ship Hybrid)
# =========================================================
#  Concept:
#  1. Embeds CMD/PS1 files inside itself (No separate downloads for core files)
#  2. Downloads only Aria2c & Icon (External Assets)
#  3. Minimizes while Installer is running -> Wakes up to cleanup
# =========================================================

param([switch]$IsLegacyMode)
$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [CONFIG]
$BaseURL = "https://raw.githubusercontent.com/itgroceries-sudo/IT-Groceries-Project/main"
$tmpDir  = "$env:TEMP"
$BinDir  = "$tmpDir\bin"
$RandomID = -join ((48..57) | Get-Random -Count 4 | % {[char]$_})

# สร้างโฟลเดอร์ bin รอไว้
if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir -Force | Out-Null }

# --- [STEP 0] SELF-HIDE (Optional) ---
if ($PSCommandPath -and (Test-Path $PSCommandPath)) {
    try { (Get-Item $PSCommandPath).Attributes = 'Hidden' } catch {}
}

# --- [STEP 1] ADMIN CHECK ---
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    # ใช้ -NoExit เพื่อดักดู Error ถ้ามีปัญหา (แก้หายวับ)
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# --- [STEP 2] VISUAL HELPERS (Window, Icon, C#) ---
$Host.UI.RawUI.WindowTitle = "IT Groceries Launcher ($RandomID) | $(Get-Date -Format 'dd-MM-yyyy HH:mm')"
try { mode con: cols=85 lines=30 } catch {}

try {
    $def = @'
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h,int n);
    [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h,int n,int w);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h,IntPtr i,int x,int y,int cx,int cy,uint f);
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
'@
    $win32 = Add-Type -MemberDefinition $def -Name 'Win32Tools' -Namespace Win32 -PassThru
    $hwnd = $win32::GetConsoleWindow()
    $style = $win32::GetWindowLong($hwnd, -16)
    [void]$win32::SetWindowLong($hwnd, -16, $style -band 0xFFFAFFFF) 
    
    # โหลด Icon ลง bin (ถ้ายังไม่มี)
    $IconFile = "$BinDir\ITGBlog.ico"
    if (-not (Test-Path $IconFile)) { try { Invoke-WebRequest -Uri "$BaseURL/bin/ITGBlog.ico" -OutFile $IconFile -UseBasicParsing } catch {} }
    
    if (Test-Path $IconFile) {
        try { (Get-Item $IconFile).Attributes = 'Hidden' } catch {}
        $hIcon = $win32::LoadImage([IntPtr]::Zero, $IconFile, 1, 0, 0, 0x10)
        if ($hIcon -ne [IntPtr]::Zero) { [void]$win32::SendMessage($hwnd, 0x80, [IntPtr]0, $hIcon); [void]$win32::SendMessage($hwnd, 0x80, [IntPtr]1, $hIcon) }
    }
} catch {}

# --- [VISUAL FUNCTIONS] ---
function Draw-Center {
    param ($Text, $Color="White", $Bg="Black")
    $W = 85; $Len = $Text.Length; if ($Len -gt $W) { $Len = $W }
    $Pad = [math]::Max(0, [int](($W - $Len) / 2))
    $Line = (" " * $Pad) + $Text + (" " * ($W - $Len - $Pad))
    Write-Host $Line -ForegroundColor $Color -BackgroundColor $Bg
}

function Type-Writer {
    param([string]$Text, [string]$Color="Green", [int]$Speed=15)
    $W = 85; $Len = $Text.Length; $Pad = [math]::Max(0, [int](($W - $Len) / 2))
    Write-Host (" " * $Pad) -NoNewline
    $Text.ToCharArray() | ForEach-Object { Write-Host $_ -NoNewline -ForegroundColor $Color; Start-Sleep -Milliseconds $Speed }
    Write-Host ""
}

function Show-Spinner {
    param([string]$Text, [int]$Loops=10, [string]$Color="Cyan")
    $Frames = @("-", "\", "|", "/")
    $Pad = " " * 25
    $OriginalPos = $host.UI.RawUI.CursorPosition
    1..$Loops | ForEach-Object {
        foreach ($f in $Frames) {
            $host.UI.RawUI.CursorPosition = $OriginalPos
            Write-Host $Pad -NoNewline
            Write-Host "[ $f ] " -ForegroundColor Cyan -NoNewline
            Write-Host $Text -ForegroundColor $Color -NoNewline
            Start-Sleep -Milliseconds 40
        }
    }
    $host.UI.RawUI.CursorPosition = $OriginalPos
    Write-Host $Pad -NoNewline
    Write-Host "[ OK ] " -ForegroundColor Green -NoNewline
    Write-Host "$Text (Done)      " -ForegroundColor DarkGray
    Write-Host ""
}

# --- [STEP 3] PASSWORD SCREEN ---
Clear-Host
Write-Host "`n"
Draw-Center "=====================================================================================" "DarkCyan"
Draw-Center "AiO ( Freeware Silent Installer ) [ Mother Ship ]" "White" "DarkCyan"
Draw-Center "Powered by IT Groceries Shop" "Cyan"
Draw-Center "=====================================================================================" "DarkCyan"
Write-Host "`n"
Draw-Center "This software is provided as FREEWARE for educational usage." "Yellow"
Draw-Center "Crafted with dedication to streamline your workflow." "Gray"
Write-Host ""
$Pad1 = " " * 19
Write-Host $Pad1 -NoNewline; Write-Host "If you find this tool helpful, please Support Us by" -ForegroundColor White
Write-Host $Pad1 -NoNewline; Write-Host "Subscribing to our YouTube Channel: " -NoNewline -ForegroundColor White; Write-Host "IT Groceries" -ForegroundColor Green
Write-Host ""
Draw-Center "Your support drives our future updates. Thank you!" "Magenta"
Write-Host "`n"

$PadInput = " " * 25
Write-Host $PadInput -NoNewline
$InputPass = Read-Host "[ SECURITY CHECK ] Enter Password"
if ($InputPass -ne "ITG2") { Write-Host "`n"; Draw-Center "ACCESS DENIED" "Red"; Start-Sleep 2; exit }

# --- [STEP 4] MOTHER SHIP PAYLOAD (Embedded Files) ---
# ตรงนี้คือการ "ฝัง" โค้ดของไฟล์อื่นๆ ลงไปใน L.ps1 โดยตรง
# คุณเจต้องเอาโค้ดของจริงมาแปะแทนที่ "..." ในส่วนนี้นะครับ

$Payloads = @{
    "$tmpDir\Installer.cmd" = @'
REM --- [PASTE INSTALLER.CMD CODE HERE] ---@echo off
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

title IT Groceries Shop - Ultimate Installer [Base on v17.5]

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

timeout /t 5
'@
    
    "$tmpDir\Database.cmd" = @'
REM --- [PASTE DATABASE.CMD CODE HERE] ---
:: =========================================================
::  DATABASE: CATEGORIZED SLOT SYSTEM
:: =========================================================

:: --- [GROUP 1] BROWSERS (Slot 01-05) ---
set "SLOT_01=chrome"
set "SLOT_02=firefox"
set "SLOT_03=edge"
:: set "SLOT_04=brave"
:: set "SLOT_05=opera"
set "SLOT_04=photoshop"

:: --- [GROUP 2] COMMUNICATION (Slot 06-10) ---
set "SLOT_06=line"
set "SLOT_07=discord"
set "SLOT_08=zoom"
set "SLOT_09=teams"
:: set "SLOT_10=..."

:: --- [GROUP 3] MULTIMEDIA & OFFICE (Slot 11-15) ---
set "SLOT_11=vlc"
set "SLOT_12=potplayer"
set "SLOT_13=libreoffice"
set "SLOT_14=obs"
set "SLOT_15=reader"

:: --- [GROUP 4] UTILITIES & TOOLS (Slot 16-20) ---
set "SLOT_16=7zip"
set "SLOT_17=anydesk"
set "SLOT_18=winrar"
set "SLOT_19=cpuz"
set "SLOT_20=everything"

:: =========================================================
::  SOFTWARE DETAILS (ID MAPPING)
:: =========================================================

:: [Browsers]
set "Name_chrome=Google Chrome"
set "P64_chrome=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
set "P32_chrome=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"

set "Name_firefox=Mozilla Firefox"
set "P64_firefox=%ProgramFiles%\Mozilla Firefox\firefox.exe"
set "P32_firefox=%ProgramFiles(x86)%\Mozilla Firefox\firefox.exe"

set "Name_edge=Microsoft Edge"
set "P64_edge=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"

set "Name_photoshop=PhotoShop 2026"

:: [Communication]
set "Name_line=LINE PC"
set "P64_line=%LocalAppData%\LINE\bin\LineLauncher.exe"

set "Name_discord=Discord"
set "P64_discord=%LocalAppData%\Discord\Update.exe"

set "Name_zoom=Zoom Meeting"
set "P64_zoom=%AppData%\Zoom\bin\Zoom.exe"

:: [Multimedia]
set "Name_vlc=VLC Media Player"
set "P64_vlc=%ProgramFiles%\VideoLAN\VLC\vlc.exe"

set "Name_potplayer=PotPlayer"
set "P64_potplayer=%ProgramFiles%\DAUM\PotPlayer\PotPlayerMini64.exe"

set "Name_libreoffice=LibreOffice"
set "P64_libreoffice=%ProgramFiles%\LibreOffice\program\soffice.exe"

:: [Tools]
set "Name_7zip=7-Zip Archiver"
set "P64_7zip=%ProgramFiles%\7-Zip\7z.exe"

set "Name_anydesk=AnyDesk Remote"
set "P64_anydesk=%ProgramFiles(x86)%\AnyDesk\AnyDesk.exe"

set "Name_cpuz=CPU-Z System Info"
set "P64_cpuz=%ProgramFiles%\CPUID\CPU-Z\cpuz.exe"

set "Name_winrar=WinRAR"
set "P64_winrar=%ProgramFiles%\WinRAR\WinRar.exe"

set "Name_teams=Microsoft Teams"

'@

    "$BinDir\Master.ps1" = @'
# --- [PASTE MASTER.PS1 CODE HERE] ---
# =========================================================
#  PUT THIS AT THE VERY TOP OF MASTER.PS1
# =========================================================
Function Global:Download-GDriveTurbo {
    param (
        [Parameter(Mandatory=$true)] [string]$ID,
        [string]$DestDir = $env:TEMP,
        [string]$Aria2Path = "$env:TEMP\aria2c.exe"
    )
    $ErrorActionPreference = 'Stop'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProbeFile  = "$DestDir\gdrive_probe_$ID.tmp"
    $CookieFile = "$DestDir\gdrive_cookies_$ID.txt"

    try {
        Write-Host "[ CLOUD ] Analyzing Google Drive File..." -ForegroundColor Cyan
        $UrlBase = "https://drive.google.com/uc?export=download&id=$ID"
        $Response = Invoke-WebRequest -Uri $UrlBase -SessionVariable session -OutFile $ProbeFile -UseBasicParsing -PassThru
        $Content = [System.IO.File]::ReadAllText($ProbeFile, [System.Text.Encoding]::UTF8)
        
        $DetectedName = "GDrive_Download_$ID.dat"
        $FinalUrl = $UrlBase
        $foundName = $false

        if ($Response.Headers["Content-Disposition"] -match 'filename="?([^";]+)"?') {
            $DetectedName = $matches[1]; $foundName = $true
        }
        if (-not $foundName) {
            if ($Content -match "download-form" -or $Content -match "confirm=") {
                if ($Content -match 'class="uc-name-size"><a[^>]+>([^<]+)</a>') { $DetectedName = $matches[1].Trim(); $foundName = $true }
                elseif ($Content -match '(?i)<title>(.*?) - Google Drive</title>') { $DetectedName = $matches[1].Trim(); $foundName = $true }
                
                $confirm = "t"; if ($Content -match 'name="confirm" value="([^"]+)"') { $confirm = $matches[1] }
                $FinalUrl = "https://drive.usercontent.google.com/download?id=$ID&export=download&confirm=$confirm"
                if ($Content -match 'name="uuid" value="([^"]+)"') { $FinalUrl += "&uuid=$($matches[1])" }
            }
        }

        $DetectedName = $DetectedName -replace '\s+', '_' -replace '[^a-zA-Z0-9._()\[\]-]', '' -replace '_{2,}', '_'
        Write-Host "[ CLOUD ] Target: $DetectedName" -ForegroundColor Green
        
        if (Test-Path $CookieFile) { Remove-Item $CookieFile -Force }
        foreach ($cookie in $session.Cookies.GetCookies([Uri]$FinalUrl)) {
            $line = "$($cookie.Domain)`tTRUE`t$($cookie.Path)`t$($cookie.Secure.ToString().ToUpper())`t$($cookie.Expires.Ticks)`t$($cookie.Name)`t$($cookie.Value)"
            Add-Content -Path $CookieFile -Value $line
        }

        if (-not (Test-Path $Aria2Path)) { 
             Write-Host " >> Installing engine..." -ForegroundColor Yellow
             Invoke-WebRequest "https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0-win-64bit-build1.zip" -OutFile "$env:TEMP\aria2.zip"
             Expand-Archive "$env:TEMP\aria2.zip" -DestinationPath "$env:TEMP\aria2_extract" -Force
             Move-Item "$env:TEMP\aria2_extract\aria2-1.36.0-win-64bit-build1\aria2c.exe" $Aria2Path -Force; Remove-Item "$env:TEMP\aria2.zip", "$env:TEMP\aria2_extract" -Recurse -Force
        }

        $FullSavePath = "$DestDir\$DetectedName"
        if (Test-Path $FullSavePath) { Remove-Item $FullSavePath -Force }
        Write-Host " >> Downloading..." -ForegroundColor Yellow
        $AriaArgs = @("-x", "16", "-s", "16", "-j", "1", "-k", "1M", "--file-allocation=none", "--console-log-level=error", "--disable-ipv6=true", "--check-certificate=false", "--load-cookies=$CookieFile", "--user-agent=Mozilla/5.0", "-d", $DestDir, "-o", $DetectedName, "$FinalUrl")
        $proc = Start-Process -FilePath $Aria2Path -ArgumentList $AriaArgs -Wait -PassThru -NoNewWindow
        if ($proc.ExitCode -ne 0) { throw "Download Failed" }
        if (-not (Test-Path $FullSavePath)) { throw "File not found" }
        return $FullSavePath
    } catch { throw } finally { if (Test-Path $ProbeFile) { Remove-Item $ProbeFile -Force -ErrorAction SilentlyContinue }; if (Test-Path $CookieFile) { Remove-Item $CookieFile -Force -ErrorAction SilentlyContinue } }
}
# =========================================================
#  ... START YOUR EXISTING MENU CODE BELOW ...
# =========================================================

# =========================================================
#  FILE: Master.ps1 (The Engine v4.0 - Ultimate Edition)
#  Enhanced by IT Groceries: IPv6 Disable, No Alloc, Anti-Rename
# =========================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# รับตัวแปรจากภายนอก: $url, $fileName, $installArgs
$dest = "$env:TEMP\$fileName"
$aria2 = "$env:TEMP\aria2c.exe"

# =========================================================
#  [CONFIG] ARIA2 ARGUMENTS (THE SECRET SAUCE)
# =========================================================
# ชุดคำสั่งมาตรฐาน (Base Args) สำหรับทุกการดาวน์โหลด
$AriaBaseArgs = @(
    "--disable-ipv6=true",        # ปิด IPv6 (แก้ปัญหาเน็ตบางค่าย/VPN)
    "--check-certificate=false",  # ไม่สน SSL (แก้ปัญหาเครื่องเก่า)
    "--file-allocation=none",     # ไม่ต้องจองพื้นที่ (เริ่มโหลดทันที)
    "--auto-file-renaming=false", # ห้ามเปลี่ยนชื่อไฟล์เอง (กันชื่อเพี้ยน)
    "--console-log-level=warn",   # ลดข้อความรกหน้าจอ
    "--user-agent=Mozilla/5.0",   # ปลอมตัวเป็น Browser
    "-j", "1",                    # 1 Concurrent Download
    "-d", "$env:TEMP",            # ปลายทาง
    "-o", "$fileName"             # ชื่อไฟล์
)

try {
    # ---------------------------------------------------------
    # 1. DOWNLOAD PHASE (Smart Logic: 16 -> 8 -> IWR)
    # ---------------------------------------------------------
    Write-Host "[ CLOUD ] Downloading $fileName..." -ForegroundColor Cyan
    
    # ถ้ามี Aria2 ให้เริ่มกระบวนการ Turbo
    if ($env:UseAria2 -eq "1" -and (Test-Path $aria2)) { 
        
        # [Attempt 1] High Speed (16 Connections)
        Write-Host "   >> Attempt 1: High Speed (16 Connections)..." -NoNewline -ForegroundColor Gray
        
        # รวม Args มาตรฐาน + Args ความเร็วสูง
        $Args16 = $AriaBaseArgs + @("-x", "16", "-s", "16", "$url")
        
        & $aria2 $Args16
        
        # ตรวจสอบผลลัพธ์
        if ($LASTEXITCODE -eq 0 -and (Test-Path $dest)) {
            Write-Host " [ OK ]" -ForegroundColor Green
        } else {
            # [Attempt 2] Standard Speed (8 Connections)
            Write-Host " [ FAIL ]" -ForegroundColor Red
            Write-Host "   >> Attempt 2: Standard Speed (8 Connections)..." -NoNewline -ForegroundColor Yellow
            
            # ลบไฟล์ขยะที่โหลดไม่เสร็จทิ้งก่อน
            if (Test-Path $dest) { Remove-Item $dest -Force }
            if (Test-Path "$dest.aria2") { Remove-Item "$dest.aria2" -Force }

            # รวม Args มาตรฐาน + Args ความเร็วปกติ
            $Args8 = $AriaBaseArgs + @("-x", "8", "-s", "8", "$url")

            & $aria2 $Args8
            
            if ($LASTEXITCODE -eq 0 -and (Test-Path $dest)) {
                Write-Host " [ OK ]" -ForegroundColor Green
            } else {
                # [Fail] ยอมแพ้แล้วใช้ตัวโหลดของ Windows
                Write-Host " [ FAIL ]" -ForegroundColor Red
                throw "Aria2 Failed. Switching to Basic Download."
            }
        }

    } else {
        # ถ้าไม่มี Aria2 ตั้งแต่ต้น ให้ข้ามไปใช้ Basic เลย
        throw "Aria2 not found. Using Basic Download."
    }

} catch {
    # [Attempt 3] (Last Resort) ใช้ Invoke-WebRequest (ช้าแต่ชัวร์)
    Write-Host "   >> Attempt 3: Basic Download (Invoke-WebRequest)..." -ForegroundColor Magenta
    try {
        if (Test-Path $dest) { Remove-Item $dest -Force }
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    } catch {
        Write-Host "[ FATAL ERROR ] Download Failed Completely." -ForegroundColor Red
        exit 1
    }
}

try {
    # ---------------------------------------------------------
    # 2. INSTALL PHASE
    # ---------------------------------------------------------
    if (Test-Path $dest) {
        Write-Host "[ CLOUD ] Installing..." -ForegroundColor Green
        
        if ($dest -like "*.msi") {
            $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$dest`" $installArgs" -Wait -PassThru
        } else {
            $proc = Start-Process -FilePath $dest -ArgumentList $installArgs -Wait -PassThru
        }
        
        # ---------------------------------------------------------
        # 3. VERIFY RESULT
        # ---------------------------------------------------------
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) { 
            Write-Host "[ SUCCESS ] Installation Complete." -ForegroundColor Green
        } else { 
            Write-Host "[ WARN ] Installer Exit Code: $($proc.ExitCode)" -ForegroundColor Yellow
        }
    } else {
        throw "File not found after download process."
    }

} catch {
    Write-Host "[ ERROR ] $_" -ForegroundColor Red
    exit 1

} finally {
    # ---------------------------------------------------------
    # 4. CLEANUP PHASE (ลบไฟล์ 100%)
    # ---------------------------------------------------------
    if (Test-Path $dest) {
        Write-Host "[ CLEANUP ] Removing installer..." -ForegroundColor Gray
        for ($i=1; $i -le 3; $i++) {
            try { Remove-Item $dest -Force -ErrorAction Stop; break } 
            catch { Start-Sleep 2 }
        }
    }
}
Function Global:Download-GDriveTurbo { Write-Host "Downloading..." }
'@

    "$BinDir\Theme.cmd" = @'
REM --- [PASTE THEME.CMD CODE HERE] ---
@echo off
:: =========================================================
::  THEME MANAGER (Icon, Window, Colors)
:: =========================================================

:: 1. กำหนดขนาดหน้าต่าง
mode con: cols=120 lines=28

:: 2. สร้างรหัสสี (ESC Code) ในนี้เลย (ชัวร์ที่สุด)
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"

:: 3. นิยามตัวแปรสี
set "Reset=%ESC%[0m" & set "Bold=%ESC%[1m"
set "Hi_White=%ESC%[97m" & set "Hi_Cyan=%ESC%[96m" & set "Hi_Yellow=%ESC%[93m" & set "Hi_Green=%ESC%[92m"
set "Bg_Blue=%ESC%[44m" & set "Bg_Green=%ESC%[42m" & set "Bg_Red=%ESC%[41m"
set "Bg_Yellow=%ESC%[43m" & set "Bg_Cyan=%ESC%[46m" & set "Bg_Magenta=%ESC%[45m" & set "Bg_White=%ESC%[47m"
set "Black=%ESC%[30m" & set "Cyan=%ESC%[36m" & set "White=%ESC%[37m"

:: 4. ตั้งค่า Icon
set "ICON_FILE=%~dp0ITGBlog.ico"
if exist "%ICON_FILE%" (
    powershell -Command ^
      "$d='[DllImport(\"user32.dll\")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);[DllImport(\"user32.dll\")] public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad);[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow();';" ^
      "$w=Add-Type -MemberDefinition $d -Name 'WinIcon' -Namespace Win32 -PassThru;" ^
      "$h=$w::GetConsoleWindow();" ^
      "$i=$w::LoadImage([IntPtr]::Zero, '%ICON_FILE%', 1, 0, 0, 0x10);" ^
      "if ($i -ne [IntPtr]::Zero) { $w::SendMessage($h, 0x80, [IntPtr]0, $i); $w::SendMessage($h, 0x80, [IntPtr]1, $i); }" >nul 2>&1
)

:: 5. ล็อคหน้าต่าง
powershell -Command ^
  "$u='[DllImport(\"user32.dll\")] public static extern int GetWindowLong(IntPtr h,int n);[DllImport(\"user32.dll\")] public static extern int SetWindowLong(IntPtr h,int n,int w);[DllImport(\"user32.dll\")] public static extern bool SetWindowPos(IntPtr h,IntPtr i,int x,int y,int cx,int cy,uint f);[DllImport(\"user32.dll\")] public static extern int DeleteMenu(IntPtr h,int n,int w);[DllImport(\"user32.dll\")] public static extern IntPtr GetSystemMenu(IntPtr h,bool b);[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow();';" ^
  "$t=Add-Type -MemberDefinition $u -Name 'Win32' -Namespace Win32 -PassThru;" ^
  "$h=$t::GetConsoleWindow();" ^
  "Add-Type -AssemblyName System.Windows.Forms;" ^
  "$s=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds;" ^
  "$x=($s.Width - (120*8))/2; $y=($s.Height - (38*18))/2;" ^
  "$t::SetWindowPos($h,0,$x,$y,0,0,0x41);" ^
  "$style=$t::GetWindowLong($h,-16);" ^
  "$t::SetWindowLong($h,-16,$style -band 0xFFFEFFFF);" ^
  "$m=$t::GetSystemMenu($h,$false);" ^
  "$t::DeleteMenu($m,0xF060,0);" >nul 2>&1


exit /b
color 17
'@

    "$BinDir\Menu.cmd" = @'
REM --- [PASTE MENU.CMD CODE HERE] ---
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
echo [MENU]
'@
}

# --- [STEP 5] EXTRACT & LOAD ASSETS ---
Clear-Host
Write-Host "`n`n"
Type-Writer "IDENTITY VERIFIED. DEPLOYING MOTHER SHIP..." "Green" 15
Start-Sleep -Milliseconds 200

# 5.1 Extract Embedded Files
Show-Spinner "Extracting Core Components..." 8 "Cyan"
foreach ($Path in $Payloads.Keys) {
    try {
        $Content = $Payloads[$Path]
        # ถ้าเป็น .cmd ใช้ ASCII (กันเพี้ยน), ถ้า .ps1 ใช้ UTF8
        $Encoding = if ($Path.EndsWith(".cmd")) { "ASCII" } else { "UTF8" }
        $Content | Out-File $Path -Encoding $Encoding -Force
    } catch {}
}

# 5.2 Download External Assets (Aria2)
if (-not (Test-Path "$BinDir\aria2c.exe")) {
    Show-Spinner "Fetching High-Speed Module (Aria2)..." 12 "Magenta"
    try {
        Invoke-WebRequest "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip" -OutFile "$tmpDir\aria2.zip"
        Expand-Archive "$tmpDir\aria2.zip" -Dest "$tmpDir\aria2_extract" -Force
        Move-Item "$tmpDir\aria2_extract\aria2-*\aria2c.exe" "$BinDir\aria2c.exe" -Force
        Remove-Item "$tmpDir\aria2.zip", "$tmpDir\aria2_extract" -Recurse -Force
        (Get-Item "$BinDir\aria2c.exe").Attributes = 'Hidden'
    } catch {}
}

# --- [STEP 6] LAUNCH & MINIMIZE ---
$InstallerFile = "$tmpDir\Installer.cmd"

if (Test-Path $InstallerFile) {
    Write-Host "`n"
    # Countdown
    $CountColors = @("Red", "Red", "Yellow", "Yellow", "Green")
    for ($i = 5; $i -ge 1; $i--) { 
        Draw-Center "INITIALIZING IN $i..." $CountColors[$i-1]
        Start-Sleep 1 
    }
    
    Write-Host "`n"
    Type-Writer ">>> LET'S GOOOO !!! <<<" "Cyan" 50
    Start-Sleep -Milliseconds 1000
    
    # Launch Installer
    $Proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$InstallerFile`" am_admin" -PassThru
    
    if ($Proc) {
        # [Minimize Strategy] หุบตัวลงไปที่ Taskbar
        # SW_SHOWMINIMIZED = 2
        $win32::ShowWindow($hwnd, 2) 
        
        # รอจนกว่า Installer จะปิด
        $Proc.WaitForExit()
        
        # [Wake Up] เด้งกลับขึ้นมา
        # SW_RESTORE = 9
        $win32::ShowWindow($hwnd, 9)
    }

    # --- [STEP 7] CLEANUP ---
    Write-Host "`n"
    Draw-Center "CLEANING UP WORKSPACE..." "Yellow"
    Start-Sleep -Seconds 1
    
    try { 
        if (Test-Path $InstallerFile) { Remove-Item $InstallerFile -Force }
        if (Test-Path "$tmpDir\Database.cmd") { Remove-Item "$tmpDir\Database.cmd" -Force }
        # ลบทั้งโฟลเดอร์ bin (หายหมดทั้ง Theme, Menu, Master, Aria2, Icon)
        if (Test-Path $BinDir) { Remove-Item $BinDir -Recurse -Force }
    } catch {}
    
    Draw-Center "ALL CLEAR. GOODBYE!" "Green"
    Start-Sleep -Seconds 2
    Exit
} else {
    Write-Host "Error: Installer Payload Missing!" -ForegroundColor Red
    Start-Sleep 3
}

