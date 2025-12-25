<#
.SYNOPSIS
    IT Groceries Cloud Bootstrapper
    หน้าที่: โหลด Project ทั้งก้อนจาก GitHub -> แตกไฟล์ลง Temp -> รัน Installer -> ลบทิ้ง
#>
$ErrorActionPreference = "SilentlyContinue"

# [CONFIG] ลิงก์ Zip ไฟล์ของ GitHub (เปลี่ยนชื่อ Repo ให้ตรงกับของคุณเจ)
# รูปแบบ: https://github.com/<User>/<Repo>/archive/refs/heads/<Branch>.zip
$RepoZipURL = "https://github.com/itgroceries-sudo/IT-Groceries-Project/archive/refs/heads/main.zip"

# ตั้งชื่อโฟลเดอร์ชั่วคราว
$WorkSpace = "$env:TEMP\ITGroceries_Cloud_Install"
$ZipFile   = "$WorkSpace\Package.zip"

# 1. เตรียมพื้นที่ (ล้างของเก่าถ้ามี)
Write-Host "[ CLOUD ] Preparing workspace..." -ForegroundColor Cyan
if (Test-Path $WorkSpace) { Remove-Item $WorkSpace -Recurse -Force }
New-Item -ItemType Directory -Path $WorkSpace | Out-Null

# 2. ดาวน์โหลด Project ทั้งก้อน (Download)
Write-Host "[ CLOUD ] Downloading latest version from GitHub..." -ForegroundColor Yellow
try {
    # ใช้ TLS 1.2 เพื่อความชัวร์กับ GitHub
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $RepoZipURL -OutFile $ZipFile -UseBasicParsing
} catch {
    Write-Host "[ ERROR ] Failed to download repository. Check internet connection." -ForegroundColor Red
    Exit
}

# 3. แตกไฟล์ (Extract)
Write-Host "[ CLOUD ] Extracting files..." -ForegroundColor Cyan
try {
    Expand-Archive -Path $ZipFile -DestinationPath $WorkSpace -Force
} catch {
    Write-Host "[ ERROR ] Failed to extract files." -ForegroundColor Red
    Exit
}

# 4. หาไฟล์ Installer.cmd (เพราะ GitHub ชอบแตกไฟล์ซ้อนโฟลเดอร์ เช่น Project-main)
$ExtractedFolder = Get-ChildItem -Path $WorkSpace -Directory | Select-Object -First 1
$TargetInstaller = "$($ExtractedFolder.FullName)\Installer.cmd"

# 5. สั่งรัน Installer (Execute)
if (Test-Path $TargetInstaller) {
    Write-Host "[ CLOUD ] Launching Installer..." -ForegroundColor Green
    Start-Sleep -Seconds 1
    
    # สั่งรันและรอจนจบ (-Wait)
    Start-Process -FilePath $TargetInstaller -ArgumentList "am_admin" -Wait
} else {
    Write-Host "[ ERROR ] Installer.cmd not found in the downloaded package!" -ForegroundColor Red
}

# 6. เก็บกวาดขยะ (Cleanup)
Write-Host "`n[ CLEANUP ] Removing temporary files..." -ForegroundColor Gray
Start-Sleep -Seconds 1
# ลบทั้งโฟลเดอร์ Workspace ทิ้งเลย (เพราะเราโหลดมาใช้ชั่วคราว)
Remove-Item $WorkSpace -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[ DONE ] Thank you for using IT Groceries Shop." -ForegroundColor Magenta


