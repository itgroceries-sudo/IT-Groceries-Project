# =========================================================
#  IT Groceries Launcher (v13.0 - The IEX Fixer)
# =========================================================
$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [CONFIG]
$BaseURL = "https://raw.githubusercontent.com/itgroceries-sudo/IT-Groceries-Project/main"
$tmpDir  = "$env:TEMP"
$BinDir  = "$tmpDir\bin"
# ตั้งชื่อไฟล์ให้ชัดเจน จะได้ตามลบถูก
$InstallerFile = "$tmpDir\Installer.cmd" 

# --- [STEP 1] ADMIN CHECK (แก้ปัญหา IEX หายวับ) ---
$CurrentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Admin..." -ForegroundColor Yellow
    # ใช้ -NoExit เพื่อให้หน้าต่างใหม่ไม่ปิดตัวเอง ถ้ามี Error เราจะเห็น
    # ใช้ -WindowStyle Normal เพื่อบังคับให้โชว์หน้าต่าง
    Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -Command `& { iex ((New-Object Net.WebClient).DownloadString('$BaseURL/Launcher.ps1')) }`" -Verb RunAs
    Exit # ปิดหน้าต่างเก่า (ที่ไม่ใช่ Admin)
}

# --- [STEP 2] PREPARE ENVIRONMENT ---
$Host.UI.RawUI.WindowTitle = "IT Groceries Cloud Loader"
if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir -Force | Out-Null }

# 2.1 โหลด Icon
$IconFile = "$BinDir\ITGBlog.ico"
try { Invoke-WebRequest -Uri "$BaseURL/bin/ITGBlog.ico" -OutFile $IconFile -UseBasicParsing } catch {}

# 2.2 โหลด Aria2c (จำเป็นต้องมี)
if (-not (Test-Path "$BinDir\aria2c.exe")) {
    try {
        Invoke-WebRequest "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip" -OutFile "$tmpDir\aria2.zip"
        Expand-Archive "$tmpDir\aria2.zip" -Dest "$tmpDir\aria2_extract" -Force
        Move-Item "$tmpDir\aria2_extract\aria2-*\aria2c.exe" "$BinDir\aria2c.exe" -Force
        Remove-Item "$tmpDir\aria2.zip", "$tmpDir\aria2_extract" -Recurse -Force
        (Get-Item "$BinDir\aria2c.exe").Attributes = 'Hidden'
    } catch {}
}

# 2.3 ตั้งค่าหน้าต่าง (C#)
try {
    $def = @'
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad);
'@
    $win32 = Add-Type -MemberDefinition $def -Name 'Win32Tools' -Namespace Win32 -PassThru
    $hwnd = $win32::GetConsoleWindow()
    
    # Set Icon
    if (Test-Path $IconFile) {
        $hIcon = $win32::LoadImage([IntPtr]::Zero, $IconFile, 1, 0, 0, 0x10)
        [void]$win32::SendMessage($hwnd, 0x80, [IntPtr]0, $hIcon); [void]$win32::SendMessage($hwnd, 0x80, [IntPtr]1, $hIcon)
    }
} catch {}

# --- [STEP 3] DOWNLOAD & RUN INSTALLER ---
Write-Host "`n [ CLOUD ] Downloading Installer.cmd (Hybrid)..." -ForegroundColor Cyan

# โหลดไฟล์ Installer.cmd (ตัวเดียวจบ)
Invoke-WebRequest -Uri "$BaseURL/Installer.cmd" -OutFile $InstallerFile -UseBasicParsing

if (Test-Path $InstallerFile) {
    Write-Host " [ START ] Launching..." -ForegroundColor Green
    Start-Sleep -Seconds 1
    
    # สั่งรัน CMD
    $Proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$InstallerFile`" am_admin" -PassThru
    
    if ($Proc) {
        # ย่อหน้าต่าง Launcher ลง (Hide)
        $win32::ShowWindow($hwnd, 2) # 2 = Minimize
        
        # รอจนกว่า Installer จะปิด
        $Proc.WaitForExit()
        
        # เด้งกลับมา (Restore)
        $win32::ShowWindow($hwnd, 9) # 9 = Restore
    }
}

# --- [STEP 4] CLEANUP ---
Write-Host "`n [ CLEANUP ] Removing traces..." -ForegroundColor Yellow
Start-Sleep -Seconds 1
try {
    if (Test-Path $InstallerFile) { Remove-Item $InstallerFile -Force }
    if (Test-Path $BinDir) { Remove-Item $BinDir -Recurse -Force }
    # ลบตัวเอง (ถ้าเป็นไฟล์)
    if ($PSCommandPath) { Remove-Item $PSCommandPath -Force }
} catch {}

Write-Host " [ DONE ] Bye" -ForegroundColor Green
Start-Sleep -Seconds 1
Exit

