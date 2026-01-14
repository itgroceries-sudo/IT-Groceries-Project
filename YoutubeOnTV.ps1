# ==========================================
# YouTube on TV Installer (Brave Edition)
# Created by: IT Groceries Shop
# ==========================================

Write-Host "Checking Brave Installation..." -ForegroundColor Cyan

# 1. ค้นหาที่อยู่ของ Brave Browser (รองรับทั้ง 64bit และ 32bit)
$BravePath = "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe"
if (-not (Test-Path $BravePath)) {
    $BravePath = "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe"
}

if (-not (Test-Path $BravePath)) {
    Write-Error "Error: Brave Browser not found! Please install Brave first."
    return
}
Write-Host "Found Brave at: $BravePath" -ForegroundColor Green

# 2. กำหนดค่าตัวแปรต่างๆ
$AppName = "YouTube on TV"
$ProfileDir = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\YouTubeTV_Mode"
$IconPath = "$ProfileDir\youtube_tv.ico"
$ShortcutPath = "$env:USERPROFILE\Desktop\$AppName.lnk"

# User Agent (Tizen 6.0) ตัวที่เสถียรที่สุด
$UserAgent = "Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/4.0 Chrome/76.0.3809.146 TV Safari/537.36"

# 3. สร้างโฟลเดอร์สำหรับเก็บข้อมูลแยก (ถ้ายังไม่มี)
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
}

# 4. ดาวน์โหลดไอคอนสวยๆ (ถ้ายังไม่มี)
# ใช้ไอคอนจาก Server ภายนอกเพื่อให้ชัดกว่า Default ของ Browser
$IconUrl = "https://cdn-icons-png.flaticon.com/512/1384/1384060.png" # ตัวอย่าง URL ไอคอน
# หมายเหตุ: PowerShell สร้าง .lnk ต้องการไฟล์ .ico ถ้าโหลด .png มาอาจต้องแปลง หรือใช้ Path ของ exe แทนถ้าไม่มี
# เพื่อความง่ายและเสถียรใน GitHub Script ผมจะใช้เทคนิคดึงไอคอนจากเว็บที่แปลงให้แล้ว หรือใช้ไอคอน Brave ไปก่อนถ้าโหลดไม่ได้

Write-Host "Downloading Custom Icon..." -ForegroundColor Cyan
try {
    # ดาวน์โหลดไฟล์ .ico (ลิงก์ตรงสำหรับ Icon YouTube แบบ .ico)
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/gist/phattarachai/0d8e8c8/raw/youtube.ico" -OutFile $IconPath -ErrorAction Stop
} catch {
    Write-Warning "Could not download custom icon. Using Brave icon instead."
    $IconPath = $BravePath # Fallback ไปใช้ไอคอน Brave
}

# 5. สร้าง Shortcut (COM Object Method)
Write-Host "Creating Desktop Shortcut..." -ForegroundColor Cyan
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)

$Shortcut.TargetPath = $BravePath
# ใส่ Argument ยาวๆ ทั้งหมดที่นี่
$Shortcut.Arguments = "--user-data-dir=""$ProfileDir"" --app=https://www.youtube.com/tv --disable-features=CalculateNativeWinOcclusion --user-agent=""$UserAgent"""
$Shortcut.IconLocation = $IconPath
$Shortcut.Description = "Open YouTube in TV Mode"
$Shortcut.Save()

Write-Host "==========================================" -ForegroundColor Green
Write-Host "Success! Shortcut created on Desktop." -ForegroundColor Green
Write-Host "Please open '$AppName' and link your phone." -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Green
