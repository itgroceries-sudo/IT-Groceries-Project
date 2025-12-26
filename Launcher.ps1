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
@echo off
REM --- [PASTE INSTALLER.CMD CODE HERE] ---
echo [INSTALLER] Running...
timeout /t 5
'@
    
    "$tmpDir\Database.cmd" = @'
REM --- [PASTE DATABASE.CMD CODE HERE] ---
set SLOT_01=Google Chrome
'@

    "$BinDir\Master.ps1" = @'
# --- [PASTE MASTER.PS1 CODE HERE] ---
Function Global:Download-GDriveTurbo { Write-Host "Downloading..." }
'@

    "$BinDir\Theme.cmd" = @'
REM --- [PASTE THEME.CMD CODE HERE] ---
color 17
'@

    "$BinDir\Menu.cmd" = @'
REM --- [PASTE MENU.CMD CODE HERE] ---
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
