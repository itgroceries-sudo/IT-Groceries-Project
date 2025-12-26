# =========================================================
#  IT Groceries Launcher (v11.0 - The Mother Ship)
# =========================================================
#  Features: 
#  1. Embeds Master/Theme/Menu inside itself (Single File)
#  2. Minimizes while Installer is running
#  3. Wakes up to cleanup temp files
# =========================================================

param([switch]$IsLegacyMode)
$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [CONFIG]
$BaseURL = "https://raw.githubusercontent.com/itgroceries-sudo/IT-Groceries-Project/main"
$tmpDir  = "$env:TEMP"
$BinDir  = "$tmpDir\bin"

# สร้างโฟลเดอร์ bin รอไว้
if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir -Force | Out-Null }

# --- [STEP 1] ADMIN CHECK ---
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# --- [STEP 2] EMBEDDED ASSETS (ฝังไฟล์ไว้ในตัว) ---
# เราจะเขียนไฟล์เหล่านี้ลงไปใน Temp เพื่อให้ Installer.cmd เรียกใช้ได้ตามปกติ

# 2.1 Master.ps1 (The Engine)
$Code_Master = @'
Function Global:Download-GDriveTurbo {
    # ... (ใส่โค้ด Master.ps1 ตัวเต็มของคุณเจตรงนี้) ...
    # ... (ผมละไว้เพื่อความสั้น แต่เวลาใช้จริงต้องก๊อปมาใส่นะครับ) ...
    Write-Host "[ENGINE] Master Loaded."
}
'@

# 2.2 Theme.cmd (Visuals)
$Code_Theme = @'
@echo off
mode con: cols=120 lines=30
color 17
title IT Groceries Shop - Ultimate Installer
'@

# 2.3 Menu.cmd (Legacy Menu Structure)
$Code_Menu = @'
@echo off
echo [ MENU LOADED ]
'@

# --- [STEP 3] EXTRACT ASSETS (คายไฟล์ลงเครื่อง) ---
Write-Host "[ INIT ] Extracting embedded resources..." -ForegroundColor Cyan
try {
    # เขียนไฟล์ลง Disk
    $Code_Master | Out-File "$BinDir\Master.ps1" -Encoding UTF8 -Force
    $Code_Theme  | Out-File "$BinDir\Theme.cmd"  -Encoding ASCII -Force # CMD ชอบ ASCII
    $Code_Menu   | Out-File "$BinDir\Menu.cmd"   -Encoding ASCII -Force
    
    # โหลด Icon (อันนี้ยังต้องโหลดจากเน็ต เพราะฝัง Binary ยาก)
    Invoke-WebRequest -Uri "$BaseURL/bin/ITGBlog.ico" -OutFile "$BinDir\ITGBlog.ico" -UseBasicParsing
} catch {
    Write-Host "[ ERROR ] Failed to write assets." -ForegroundColor Red; Pause; Exit
}

# --- [STEP 4] PREPARE INSTALLER & ARIA2 ---
$InstallerFile = "$tmpDir\Installer.cmd"

# 4.1 โหลด Installer.cmd ตัวจริงมา
Write-Host "[ DOWNLOAD ] Fetching Installer..." -ForegroundColor Yellow
Invoke-WebRequest -Uri "$BaseURL/Installer.cmd" -OutFile $InstallerFile -UseBasicParsing
Invoke-WebRequest -Uri "$BaseURL/Database.cmd" -OutFile "$tmpDir\Database.cmd" -UseBasicParsing

# 4.2 โหลด Aria2 (ถ้าไม่มี)
if (-not (Test-Path "$BinDir\aria2c.exe")) {
    Write-Host "[ DOWNLOAD ] Fetching Aria2 Engine..." -ForegroundColor Magenta
    try {
        Invoke-WebRequest "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip" -OutFile "$tmpDir\aria2.zip"
        Expand-Archive "$tmpDir\aria2.zip" -Dest "$tmpDir\aria2_extract" -Force
        Move-Item "$tmpDir\aria2_extract\aria2-*\aria2c.exe" "$BinDir\aria2c.exe" -Force
        Remove-Item "$tmpDir\aria2.zip", "$tmpDir\aria2_extract" -Recurse -Force
    } catch {}
}

# --- [STEP 5] LAUNCH & MINIMIZE (ไฮไลท์สำคัญ) ---
Write-Host "`n[ LAUNCH ] Starting Installer..." -ForegroundColor Green
Start-Sleep -Seconds 2

# เพิ่มความสามารถในการ Minimize หน้าต่าง PowerShell
$Win32 = Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Name "Win32Minimize" -Namespace Win32 -PassThru
$hWnd = (Get-Process -Id $PID).MainWindowHandle

# สั่งรัน Installer.cmd และรอจนกว่าจะปิด (-Wait)
$Proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$InstallerFile`" am_admin" -PassThru

if ($Proc) {
    # สั่งย่อหน้าต่าง PowerShell นี้ลง (Minimize) แต่ไม่ปิด
    # เลข 2 = SW_SHOWMINIMIZED
    $Win32::ShowWindow($hWnd, 2) 
    
    # รอจนกว่า Installer (CMD) จะถูกปิด
    $Proc.WaitForExit()
    
    # พอ Installer ปิดแล้ว ให้ PowerShell เด้งกลับขึ้นมา (Restore)
    # เลข 9 = SW_RESTORE
    $Win32::ShowWindow($hWnd, 9) 
}

# --- [STEP 6] CLEANUP (เก็บกวาดเรียบ) ---
Write-Host "`n[ CLEANUP ] Removing temporary files..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

# ลบทุกอย่างที่สร้างมา
try { 
    if (Test-Path $InstallerFile) { Remove-Item $InstallerFile -Force }
    if (Test-Path "$tmpDir\Database.cmd") { Remove-Item "$tmpDir\Database.cmd" -Force }
    # ลบทั้งโฟลเดอร์ bin ที่เราสร้างไว้ (Master, Theme, Menu, Aria2 จะหายไปหมดตรงนี้)
    if (Test-Path $BinDir) { Remove-Item $BinDir -Recurse -Force }
} catch {}

Write-Host "[ DONE ] Clean exit." -ForegroundColor Green
Start-Sleep -Seconds 1
Exit
