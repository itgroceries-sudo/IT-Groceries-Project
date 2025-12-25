# =========================================================
#  IT Groceries Cloud Bootstrapper (v9.0 - Hybrid Blockbuster)
# =========================================================
#  Concept: Visuals from GitLab + In-Memory Engine from GitHub
# =========================================================

$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [CONFIG]
$BaseURL = "https://raw.githubusercontent.com/itgroceries-sudo/IT-Groceries-Project/main"
$tmpDir  = "$env:TEMP"
$IconFile = "$tmpDir\ITGBlog.ico"
$RandomID = -join ((48..57) | Get-Random -Count 4 | % {[char]$_})

# --- [STEP 1] ADMIN CHECK (Robust Method) ---
$CurrentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # ใช้ -NoExit ตามที่คุณเจต้องการ เพื่อดัก Error
    Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- [STEP 2] VISUAL HELPERS (C# Window & Icon) ---
$Host.UI.RawUI.WindowTitle = "IT Groceries Cloud Loader ($RandomID)"
try { mode con: cols=85 lines=25 } catch {}

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
    
    # Lock Window Size
    $style = $win32::GetWindowLong($hwnd, -16)
    [void]$win32::SetWindowLong($hwnd, -16, $style -band 0xFFFAFFFF) 

    # Load Icon (ต้องโหลดไฟล์ Icon ลง Temp เพราะ C# ต้องการ Path ไฟล์)
    if (-not (Test-Path $IconFile)) { 
        try { Invoke-WebRequest -Uri "$BaseURL/bin/ITGBlog.ico" -OutFile $IconFile -UseBasicParsing } catch {} 
    }
    if (Test-Path $IconFile) {
        $hIcon = $win32::LoadImage([IntPtr]::Zero, $IconFile, 1, 0, 0, 0x10)
        if ($hIcon -ne [IntPtr]::Zero) { 
            [void]$win32::SendMessage($hwnd, 0x80, [IntPtr]0, $hIcon)
            [void]$win32::SendMessage($hwnd, 0x80, [IntPtr]1, $hIcon) 
        }
    }
} catch {}

# --- [VISUAL FUNCTIONS] ---
function Draw-Center {
    param ($Text, $Color="White", $Bg="Black")
    $W = 85; $Len = $Text.Length; if ($Len -gt $W) { $Len = $W }
    $Pad = [math]::Max(0, [int](($W - $Len) / 2))
    Write-Host ((" " * $Pad) + $Text + (" " * ($W - $Len - $Pad))) -ForegroundColor $Color -BackgroundColor $Bg
}

function Type-Writer {
    param([string]$Text, [string]$Color="Green", [int]$Speed=15)
    $W = 85; $Len = $Text.Length; $Pad = [math]::Max(0, [int](($W - $Len) / 2))
    Write-Host (" " * $Pad) -NoNewline
    $Text.ToCharArray() | ForEach-Object { Write-Host $_ -NoNewline -ForegroundColor $Color; Start-Sleep -Milliseconds $Speed }
    Write-Host ""
}

function Show-Spinner {
    param([string]$Text, [int]$Loops=6, [string]$Color="Cyan")
    $Frames = @("-", "\", "|", "/")
    $Pad = " " * 20
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
    Write-Host "$Text (Ready)    " -ForegroundColor DarkGray
    Write-Host ""
}

# --- [STEP 3] PASSWORD SCREEN ---
Clear-Host
Write-Host "`n`n"
Draw-Center "=====================================================================================" "DarkCyan"
Draw-Center "IT GROCERIES SHOP ( Cloud Bootstrapper )" "White" "DarkCyan"
Draw-Center "Github Edition" "Cyan"
Draw-Center "=====================================================================================" "DarkCyan"
Write-Host "`n"

$PadInput = " " * 25
Write-Host $PadInput -NoNewline
$InputPass = Read-Host "[ SECURITY ] Enter Password"
if ($InputPass -ne "ITG2") { 
    Write-Host "`n"; Draw-Center "ACCESS DENIED" "Red"; Start-Sleep 2; exit 
}

# --- [STEP 4] IN-MEMORY LOADING (The GitHub Logic) ---
Clear-Host
Write-Host "`n`n"
Type-Writer "AUTHENTICATION SUCCESSFUL." "Green" 10
Start-Sleep -Milliseconds 200

# ตัวแปรสำหรับเก็บโค้ด (ยังไม่โหลด)
$Global:MasterCode = $null
$Global:LauncherCode = $null

# 4.1 Load Master Engine
Show-Spinner "Downloading Core Engine..." 10 "Yellow"
try {
    $Global:MasterCode = (Invoke-WebRequest -Uri "$BaseURL/bin/Master.ps1" -UseBasicParsing).Content
} catch {
    Draw-Center "FAILED TO LOAD CORE ENGINE" "Red"; Read-Host; exit
}

# 4.2 Load Launcher UI
Show-Spinner "Downloading Interface..." 10 "Yellow"
try {
    $Global:LauncherCode = (Invoke-WebRequest -Uri "$BaseURL/Launcher.ps1" -UseBasicParsing).Content
} catch {
    Draw-Center "FAILED TO LOAD LAUNCHER" "Red"; Read-Host; exit
}

# 4.3 Set Cloud Flags
Show-Spinner "Configuring Environment..." 5 "Magenta"
$Global:CloudMode = $true
$Global:CloudBaseURL = $BaseURL

# --- [STEP 5] LAUNCH ---
Write-Host "`n"
Draw-Center ">>> SYSTEM READY - LAUNCHING <<<" "White" "DarkBlue"
Start-Sleep -Seconds 1

try {
    # รวมร่างและรัน (In-Memory Execution)
    Invoke-Expression "$Global:MasterCode`n`n$Global:LauncherCode"
    
    # เมื่อจบการทำงาน
    Write-Host "`n"
    Draw-Center "SESSION TERMINATED" "Gray"
    
    # Cleanup Icon
    if (Test-Path $IconFile) { Remove-Item $IconFile -Force -ErrorAction SilentlyContinue }
    
    # Read-Host "Press Enter to exit..." # เปิดบรรทัดนี้ถ้าอยากให้รอปิด

} catch {
    Write-Host "`n"
    Draw-Center "CRITICAL RUNTIME ERROR" "Red"
    Write-Host "Details: $_" -ForegroundColor Gray
    Read-Host "Press Enter to exit..."
}
