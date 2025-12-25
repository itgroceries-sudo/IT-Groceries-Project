# =========================================================
#  FILE: inst_photoshop.ps1
# =========================================================

# 1. กำหนดค่า (Config)
$MyID = "1n6ORbTF9mVV7u2d4iaZevaS5kITv_Vpv"  # <--- ใส่ ID ไฟล์ตรงนี้
$InstallPath = "C:\Program Files\Adobe"      # <--- ที่ที่จะลงโปรแกรม

try {
    # 2. เรียกใช้ฟังก์ชันจาก Master (สั่งโหลด)
    # มันจะคืนค่า Path ของไฟล์ที่โหลดเสร็จมาเก็บในตัวแปร $DownloadedFile
    $DownloadedFile = Download-GDriveTurbo -ID $MyID

    # 3. สั่งแตกไฟล์ / ติดตั้ง
    Write-Host " >> Extracting file..." -ForegroundColor Yellow
    
    # ตัวอย่าง: แตกไฟล์ด้วย 7-Zip (สมมติว่ามี 7z.exe อยู่ใน Temp หรือ Path)
    & "7z.exe" x "$DownloadedFile" -o"$InstallPath" -y
    
    # หรือถ้าเป็นไฟล์ .exe ให้รัน setup ต่อ
    # Start-Process "$InstallPath\Setup.exe" -ArgumentList "/Silent" -Wait

    Write-Host " >> Installation Complete!" -ForegroundColor Green

} catch {
    Write-Host " [ERROR] $_" -ForegroundColor Red
    # สั่งให้หยุดดู Error ก่อนปิด (ถ้าต้องการ)
    Read-Host "Press ENTER to exit..."
}
