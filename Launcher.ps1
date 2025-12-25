# =========================================================
#  FILE: Bootstrapper.ps1 (Fixed & Debug Ready)
# =========================================================

# 1. ขอสิทธิ์ Admin
$CurrentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host " [ SYSTEM ] Requesting Administrator Privileges..." -ForegroundColor Yellow
    try {
        # [FIX 1] เพิ่ม -NoExit เพื่อดักดู Error (ถ้ามันพัง มันจะไม่ปิดหนี)
        Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    } catch {
        Write-Host " [ ERROR ] Failed to elevate. Please run as Administrator manually." -ForegroundColor Red
        Pause; Exit
    }
}

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [FIX 2] เติม $ หน้าตัวแปร (นี่คือตัวการที่ทำให้หายวับ!)
$BaseURL = "https://raw.githubusercontent.com/itgroceries-sudo/IT-Groceries-Project/main"

Write-Host "`n [ CLOUD ] Connecting to IT Groceries Repository..." -ForegroundColor Cyan

try {
    # 2. โหลด Master Engine
    Write-Host "    >> Loading Core Engine (Master)..." -NoNewline
    $MasterCode = (Invoke-WebRequest -Uri "$BaseURL/bin/Master.ps1" -UseBasicParsing).Content
    Write-Host " [ OK ]" -ForegroundColor Green

    # 3. โหลด Launcher Interface
    Write-Host "    >> Loading Interface (Launcher)..." -NoNewline
    $LauncherCode = (Invoke-WebRequest -Uri "$BaseURL/Launcher.ps1" -UseBasicParsing).Content
    Write-Host " [ OK ]" -ForegroundColor Green

    # 4. ตั้งค่า Cloud Mode
    $Global:CloudMode = $true
    $Global:CloudBaseURL = $BaseURL

    Write-Host "`n [ START ] Launching System..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    
    # 5. รันระบบ
    # รวมโค้ด Master และ Launcher เข้าด้วยกันแล้วรันใน Memory
    Invoke-Expression "$MasterCode`n`n$LauncherCode"
    
    # กันเหนียว: ถ้า Launcher จบการทำงาน ให้รอ Spacebar ก่อนปิด
    Write-Host "`n [ INFO ] Application Closed." -ForegroundColor Gray
    # Read-Host " Press Enter to exit..." 

} catch {
    # ถ้ามี Error จะมาตกตรงนี้ และหน้าต่างจะไม่ปิดเพราะเราใส่ -NoExit ไว้ตอนเริ่ม
    Write-Host "`n [ ERROR ] Critical Failure!" -ForegroundColor Red
    Write-Host " Details: $_" -ForegroundColor Gray
    Write-Host " Please check your internet connection or GitHub URL." -ForegroundColor Yellow
    Read-Host " Press Enter to exit..."
}
