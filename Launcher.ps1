# =========================================================
#  IT Groceries Shop Launcher (v10.0 - GitHub Blockbuster)
# =========================================================
param([switch]$IsLegacyMode)
$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [CONFIG] เปลี่ยน BaseURL เป็น GitHub (Raw)
$BaseURL = "https://raw.githubusercontent.com/itgroceries-sudo/IT-Groceries-Project/main"
$tmpDir  = "$env:TEMP"

# สุ่มชื่อไฟล์ Launcher (กันไฟล์ซ้ำ)
$RandomID = -join ((48..57) | Get-Random -Count 4 | % {[char]$_})
$LauncherFile = "$tmpDir\ITG_Launcher_$RandomID.ps1"
$IconFile = "$tmpDir\ITGBlog.ico" # เปลี่ยนตามข้อ 2

# สร้างโฟลเดอร์ bin ใน Temp รอไว้เลย (เพื่อให้ Installer.cmd มองเห็น)
if (-not (Test-Path "$tmpDir\bin")) { New-Item -ItemType Directory -Path "$tmpDir\bin" -Force | Out-Null }

# --- [STEP 0] SELF-HIDE ---
if ($PSCommandPath -and (Test-Path $PSCommandPath)) {
    try { (Get-Item $PSCommandPath).Attributes = 'Hidden' } catch {}
}

# --- [STEP 1] ADMIN CHECK ---
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $PSCommandPath -or -not $IsAdmin) {
    # ถ้าไม่ใช่ Admin ให้โหลดตัวเองใหม่แล้วรันเป็น Admin
    if (-not $PSCommandPath) { 
        try { Invoke-WebRequest -Uri "$BaseURL/Launcher.ps1" -OutFile $LauncherFile -UseBasicParsing } catch { exit } 
        $TargetFile = $LauncherFile 
    } else { 
        $TargetFile = $PSCommandPath 
    }
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TargetFile`"" -Verb RunAs; exit
}

# --- [STEP 2] VISUAL HELPERS ---
$Host.UI.RawUI.WindowTitle = "IT Groceries Launcher ($RandomID)"
try { mode con: cols=85 lines=25 } catch {}

# 2.1 Window & Icon
try {
    $def = @'
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h,int n);
    [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h,int n,int w);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h,IntPtr i,int x,int y,int cx,int cy,uint f);
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad);
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
'@
    $win32 = Add-Type -MemberDefinition $def -Name 'Win32Tools' -Namespace Win32 -PassThru
    $hwnd = $win32::GetConsoleWindow()
    $style = $win32::GetWindowLong($hwnd, -16)
    [void]$win32::SetWindowLong($hwnd, -16, $style -band 0xFFFAFFFF) 
    
    # พยายามโหลด Icon จาก GitHub ถ้าไม่มีในเครื่อง
    if (-not (Test-Path $IconFile)) { try { Invoke-WebRequest -Uri "$BaseURL/bin/ITGBlog.ico" -OutFile $IconFile -UseBasicParsing } catch {} }
    
    if (Test-Path $IconFile) {
        try { (Get-Item $IconFile).Attributes = 'Hidden' } catch {}
        $hIcon = $win32::LoadImage([IntPtr]::Zero, $IconFile, 1, 0, 0, 0x10)
        if ($hIcon -ne [IntPtr]::Zero) { [void]$win32::SendMessage($hwnd, 0x80, [IntPtr]0, $hIcon); [void]$win32::SendMessage($hwnd, 0x80, [IntPtr]1, $hIcon) }
    }
} catch {}

# 2.2 Helper Functions
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
    Write-Host "$Text (Done)     " -ForegroundColor DarkGray
    Write-Host ""
}

# --- [STEP 3] PASSWORD SCREEN ---
Clear-Host
Write-Host "`n"
Draw-Center "=====================================================================================" "DarkCyan"
Draw-Center "AiO ( Freeware Silent Installer ) [ GitHub UI ]" "White" "DarkCyan"
Draw-Center "Powered by IT Groceries Shop" "Cyan"
Draw-Center "=====================================================================================" "DarkCyan"
Write-Host "`n"

$PadInput = " " * 25
Write-Host $PadInput -NoNewline
$InputPass = Read-Host "[ SECURITY CHECK ] Enter Password"
if ($InputPass -ne "ITG2") { Write-Host "`n"; Draw-Center "ACCESS DENIED" "Red"; Start-Sleep 2; exit }

# --- [STEP 4] ASSET LOADER (GitHub Structure) ---
Clear-Host
Write-Host "`n`n"
Type-Writer "IDENTITY VERIFIED. ACCESS GRANTED." "Green" 15
Start-Sleep -Milliseconds 200
Show-Spinner "Establishing Secure Connection..." 15 "Cyan"

$InstID = -join ((48..57) | Get-Random -Count 4 | % {[char]$_})
$InstallerFile = "$tmpDir\Installer.cmd" # ใช้ชื่อนี้เพื่อให้ Path ตรงกัน

# รายการไฟล์ที่จะโหลด (Mapping GitHub -> Local Temp)
$Assets = @(
    # [ROOT FILES]
    @{ Url="$BaseURL/Installer.cmd";      Dest="$tmpDir\Installer.cmd";    Msg="Fetching Installer..." },
    @{ Url="$BaseURL/Database.cmd";       Dest="$tmpDir\Database.cmd";     Msg="Fetching Database..." },
    
    # [BIN FILES] (ลงในโฟลเดอร์ bin ที่สร้างไว้)
    @{ Url="$BaseURL/bin/Master.ps1";     Dest="$tmpDir\bin\Master.ps1";   Msg="Injecting Engine..." },
    @{ Url="$BaseURL/bin/Theme.cmd";      Dest="$tmpDir\bin\Theme.cmd";    Msg="Loading Theme..." },
    @{ Url="$BaseURL/bin/Menu.cmd";       Dest="$tmpDir\bin\Menu.cmd";     Msg="Loading Menu..." },
    @{ Url="$BaseURL/bin/ITGBlog.ico";    Dest="$tmpDir\bin\ITGBlog.ico";  Msg="Loading Icon..." }
    # Google.ico ไม่ต้องโหลดก็ได้ ถ้า Installer ใช้ ITGBlog.ico เหมือนกัน
)

foreach ($item in $Assets) {
    Show-Spinner $item.Msg 5 "Yellow"
    try {
        if (Test-Path $item.Dest) { Remove-Item $item.Dest -Force -ErrorAction SilentlyContinue }
        Invoke-WebRequest -Uri $item.Url -OutFile $item.Dest -UseBasicParsing
    } catch {}
}

# --- [STEP 5] ARIA2C MANAGER (Auto Download Zip) ---
# ทำตามข้อ 7: ลบ aria2c.exe จาก git แล้วโหลด zip มาแตกแทน
# Installer.cmd ปกติจะหา bin\aria2c.exe ดังนั้นเราต้องย้ายไปที่ bin
$AriaPath = "$tmpDir\bin\aria2c.exe"

if (-not (Test-Path $AriaPath)) {
    Show-Spinner "Fetching High-Speed Module (Aria2)..." 12 "Magenta"
    try {
        Invoke-WebRequest "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip" -OutFile "$tmpDir\aria2.zip"
        Expand-Archive "$tmpDir\aria2.zip" -Dest "$tmpDir\aria2_extract" -Force
        
        # ย้ายไฟล์ exe เข้า bin
        Move-Item "$tmpDir\aria2_extract\aria2-*\aria2c.exe" "$tmpDir\bin\aria2c.exe" -Force
        
        # ลบขยะจากการแตกไฟล์
        Remove-Item "$tmpDir\aria2.zip", "$tmpDir\aria2_extract" -Recurse -Force
        (Get-Item $AriaPath).Attributes = 'Hidden'
    } catch {}
}

# --- [STEP 6] LAUNCH ---
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
    Start-Sleep -Milliseconds 1500
    
    # Launch Installer.cmd (และส่ง parameter am_admin)
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$InstallerFile`" am_admin" -Wait
    
    # --- [STEP 7] CLEANUP (ตามคำขอเป๊ะๆ) ---
    try { if (Test-Path $InstallerFile) { Remove-Item $InstallerFile -Force -ErrorAction SilentlyContinue } } catch {}
    try { if (Test-Path $TargetFile) { Remove-Item $TargetFile -Force -ErrorAction SilentlyContinue } } catch {}
    try { if (Test-Path $LauncherFile) { Remove-Item $LauncherFile -Force -ErrorAction SilentlyContinue } } catch {}
    try { if (Test-Path $IconFile) { Remove-Item $IconFile -Force -ErrorAction SilentlyContinue } } catch {}
    # แถม: ลบโฟลเดอร์ bin ที่สร้างไว้ด้วย เพื่อความสะอาดหมดจด
    try { if (Test-Path "$tmpDir\bin") { Remove-Item "$tmpDir\bin" -Recurse -Force -ErrorAction SilentlyContinue } } catch {}
    
    exit
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Start-Sleep 3
}
