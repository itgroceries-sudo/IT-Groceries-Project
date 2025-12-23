<#
.SYNOPSIS
    IT Groceries Launcher (Manager)
    หน้าที่: เปิด Installer -> รอจนจบ -> ลบไฟล์ขยะใน TEMP (แต่ห้ามยุ่งกับ bin หลัก)
#>
$ErrorActionPreference = "SilentlyContinue"
$WorkDir = $PSScriptRoot
$InstallerCMD = "$WorkDir\Installer.cmd"

# [CONFIG] รายชื่อไฟล์ที่ต้องการลบ (Target: Temp Files Only)
# ⚠️ สำคัญ: อย่าใส่ $WorkDir\bin ในนี้เด็ดขาด เพราะจะทำให้ไฟล์หลักหาย
$CleanupList = @(
    "$env:TEMP\aria2c.exe",     # ลบตัวสำเนาใน Temp
    "$env:TEMP\Master.ps1",     # ลบตัวสำเนาใน Temp
    "$WorkDir\Changes.log"      # ลบ Log (อันนี้แล้วแต่ครับ ลบก็ได้ ไม่ลบก็ได้)
)

# 1. เริ่มต้น Installer UI
if (Test-Path $InstallerCMD) {
    Write-Host "[ LAUNCHER ] Starting IT Groceries Installer..." -ForegroundColor Cyan
    
    # สั่งรันและรอจนกว่าจะปิด (-Wait)
    Start-Process -FilePath $InstallerCMD -ArgumentList "am_admin" -Wait
} else {
    Write-Host "[ ERROR ] Installer.cmd not found!" -ForegroundColor Red
    Start-Sleep 3
    Exit
}

# 2. พื้นที่ Clean Up (ทำงานหลังจาก CMD ปิดแล้ว)
Write-Host "`n[ LAUNCHER ] Cleaning up temporary files..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

foreach ($File in $CleanupList) {
    if (Test-Path $File) {
        Remove-Item -Path $File -Force -ErrorAction SilentlyContinue
        Write-Host "   - Removed: $(Split-Path $File -Leaf)" -ForegroundColor Gray
    }
}

Write-Host "[ FINISHED ] System Cleaned. See you next time!" -ForegroundColor Green
Start-Sleep -Seconds 2