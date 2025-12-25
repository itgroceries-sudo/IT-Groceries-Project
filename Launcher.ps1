# =========================================================
#  FILE: Bootstrapper.ps1 (The Cloud Key)
# =========================================================
#  หน้าที่: ดึง Launcher ตัวจริงจาก GitHub มารันใน Memory ทันที
# =========================================================

# 1. ขอสิทธิ์ Admin (ถ้ายังไม่มี)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Admin Privileges..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- [CONFIG] ---
# ลิงก์ไปยังไฟล์ Launcher.ps1 (แบบ Raw) บน GitHub ของคุณเจ
# ต้องเป็นลิงก์ "Raw" นะครับ (กดปุ่ม Raw ใน GitHub แล้วก๊อปมา)
$LauncherUrl = "https://raw.githubusercontent.com/itgroceries-sudo/IT-Groceries-Project/main/Launcher.ps1"

# ลิงก์ไปยัง Master.ps1 (เพื่อให้ Launcher โหลดต่อได้)
$MasterUrl   = "https://raw.githubusercontent.com/itgroceries-sudo/IT-Groceries-Project/main/bin/Master.ps1"

Write-Host "`n[ CLOUD ] Connecting to IT Groceries Repository..." -ForegroundColor Cyan

try {
    # 2. ดึงโค้ด Master.ps1 มาลง Memory ไว้ก่อน (Pre-load Engine)
    Write-Host " >> Loading Core Engine..." -NoNewline
    $MasterCode = (Invoke-WebRequest -Uri $MasterUrl -UseBasicParsing).Content
    
    # 3. ดึงโค้ด Launcher.ps1 มาลง Memory
    Write-Host "`n >> Loading Interface..." -NoNewline
    $LauncherCode = (Invoke-WebRequest -Uri $LauncherUrl -UseBasicParsing).Content
    
    Write-Host " [ OK ]" -ForegroundColor Green
    Start-Sleep -Seconds 1

    # 4. แปลงร่าง! (สั่งรันโค้ดทั้งหมดใน Memory)
    # เราจะฉีดโค้ด Master เข้าไปแปะหน้า Launcher เลย เพื่อให้มันรู้จักฟังก์ชันทันที
    $FinalPayload = "$MasterCode`n`n$LauncherCode"
    
    # สั่งรัน!
    Invoke-Expression $FinalPayload

} catch {
    Write-Host "`n[ ERROR ] Failed to connect to Cloud Repository." -ForegroundColor Red
    Write-Host "Details: $_" -ForegroundColor Gray
    Write-Host "Check your internet connection or URL." -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
}
