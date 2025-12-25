# =========================================================
#  FILE: Bootstrapper.ps1 (Cloud Loader - Debug Mode)
# =========================================================

# 1. ขอ Admin (เพิ่ม -NoExit เพื่อดักดู Error)
$CurrentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host " [ SYSTEM ] Requesting Administrator Privileges..." -ForegroundColor Yellow
    try {
        # [FIX] ใส่ -NoExit เพื่อให้หน้าต่าง Admin ไม่ปิดตัวเองถ้า Error
        Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    } catch {
        Write-Host " [ ERROR ] Failed to elevate. Please run as Administrator manually." -ForegroundColor Red
        Pause; Exit
    }
}

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [FIX] ใส่ $ หน้าตัวแปร (นี่คือสาเหตุที่มันหายวับ!)
$BaseURL = "https://raw.githubusercontent.com/itgroceries-sudo/IT-Groceries-Project/main"

Write-Host "`n [ CLOUD ] Connecting to IT Groceries Repository..." -ForegroundColor Cyan

try {
    # 2. โหลด Master
    Write-Host "    >> Loading Core Engine (Master)..." -NoNewline
    $MasterCode = (Invoke-WebRequest -Uri "$BaseURL/bin/Master.ps1" -UseBasicParsing).Content
    Write-Host " [ OK ]" -ForegroundColor Green

    # 3. โหลด Launcher
    Write-Host "    >> Loading Interface (Launcher)..." -NoNewline
    $LauncherCode = (Invoke-WebRequest -Uri "$BaseURL/Launcher.ps1" -UseBasicParsing).Content
    Write-Host " [ OK ]" -ForegroundColor Green

    # 4. ตั้งค่าตัวแปร Cloud Mode
    $Global:CloudMode = $true
    $Global:CloudBaseURL = $BaseURL

    Write-Host "`n [ START ] Launching System..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    
    # 5. รัน!
    Invoke-Expression "$MasterCode`n`n$LauncherCode"
    
    # [FIX] ใส่ Read-Host กันเหนียว เผื่อรันเสร็จแล้วมันปิดเลย
    Write-Host "`n [ INFO ] Application Closed." -ForegroundColor Gray
    Read-Host " Press Enter to exit..."

} catch {
    Write-Host "`n [ ERROR ] Connection Failed or Script Error" -ForegroundColor Red
    Write-Host " Details: $_" -ForegroundColor Gray
    Write-Host " Please check your internet connection and GitHub URL." -ForegroundColor Yellow
    Read-Host " Press Enter to exit..."
}
