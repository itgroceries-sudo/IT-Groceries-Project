# =========================================================
#  FILE: Bootstrapper.ps1 (Run This on Client Machine)
# =========================================================

# --- [STEP 1] AUTO-ELEVATE ADMIN (ส่วนที่หายไป) ---
$CurrentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host " [ SYSTEM ] Requesting Administrator Privileges..." -ForegroundColor Yellow
    try {
        # สั่งรันตัวเองใหม่ด้วยสิทธิ์ Admin
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit # ปิดตัวเก่า
    } catch {
        Write-Host " [ ERROR ] Failed to elevate. Please run as Administrator manually." -ForegroundColor Red
        Pause; Exit
    }
}

# --- [STEP 2] CONFIGURATION ---
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ** แก้ตรงนี้ให้เป็น GitHub ของคุณเจ **
$BaseURL = "https://raw.githubusercontent.com/itgroceries-sudo/IT-Groceries-Project/main"

Write-Host "`n [ CLOUD ] Connecting to IT Groceries Repository..." -ForegroundColor Cyan

try {
    # 2.1 โหลด Master Engine (Core Functions) มาลง RAM
    Write-Host "   >> Loading Core Engine (Master)..." -NoNewline
    $MasterCode = (Invoke-WebRequest -Uri "$BaseURL/bin/Master.ps1" -UseBasicParsing).Content
    Write-Host " [ OK ]" -ForegroundColor Green

    # 2.2 โหลด Launcher (UI) มาลง RAM
    Write-Host "   >> Loading Interface (Launcher)..." -NoNewline
    $LauncherCode = (Invoke-WebRequest -Uri "$BaseURL/Launcher.ps1" -UseBasicParsing).Content
    Write-Host " [ OK ]" -ForegroundColor Green

    # 2.3 ตั้งค่าตัวแปรพิเศษ เพื่อบอก Launcher ว่า "ฉันรันจาก Cloud อยู่นะ"
    # Launcher จะได้รู้ว่าต้องไปดึงไฟล์ลูกจาก URL นี้
    $Global:CloudMode = $true
    $Global:CloudBaseURL = $BaseURL

    # --- [STEP 3] EXECUTE (รวมร่างแล้วรัน) ---
    Write-Host "`n [ START ] Launching System..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    
    # ฉีด Master เข้าไปก่อน แล้วตามด้วย Launcher
    Invoke-Expression "$MasterCode`n`n$LauncherCode"

} catch {
    Write-Host "`n [ ERROR ] Connection Failed!" -ForegroundColor Red
    Write-Host " Details: $_" -ForegroundColor Gray
    Write-Host " Please check your internet connection." -ForegroundColor Yellow
    Read-Host " Press Enter to exit..."
}
