# ==========================================
# YouTube on TV Installer (Final Version)
# Created by: IT Groceries Shop
# ==========================================

Write-Host "Checking Browser Installation..." -ForegroundColor Cyan

# --- 1. ตรวจสอบ Browser (Priority: Brave -> Chrome) ---
$BrowserPath = $null
$BrowserName = ""
$UserDataBase = ""

# Path ที่เป็นไปได้
$BravePaths = @("$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe", "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe", "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe")
$ChromePaths = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe")

# เช็ค Brave
foreach ($path in $BravePaths) { if (Test-Path $path) { $BrowserPath = $path; $BrowserName = "Brave"; $UserDataBase = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"; break } }

# ถ้าไม่มี Brave เช็ค Chrome
if (-not $BrowserPath) {
    foreach ($path in $ChromePaths) { if (Test-Path $path) { $BrowserPath = $path; $BrowserName = "Chrome"; $UserDataBase = "$env:LOCALAPPDATA\Google\Chrome\User Data"; break } }
}

if (-not $BrowserPath) { Write-Error "Error: No supported browser found."; Start-Sleep -Seconds 5; return }
Write-Host "Found Browser: $BrowserName" -ForegroundColor Green

# --- 2. ตั้งค่า Path ---
$AppName = "YouTube on TV"
$ProfileDir = "$UserDataBase\YouTubeTV_Mode"
$IconPath = "$ProfileDir\youtube_tv.ico"
$ShortcutPath = "$env:USERPROFILE\Desktop\$AppName.lnk"
$UserAgent = "Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/4.0 Chrome/76.0.3809.146 TV Safari/537.36"

# สร้างโฟลเดอร์ Profile (ถ้ายังไม่มี)
if (-not (Test-Path $ProfileDir)) { 
    Write-Host "Creating Profile Directory..." -ForegroundColor Gray
    New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null 
}

# --- 3. ดาวน์โหลดไอคอน (ใช้แหล่งที่เชื่อถือได้) ---
Write-Host "Downloading Icon..." -ForegroundColor Cyan

# แหล่งที่มาของไอคอน:
# 1. favicon.ico ของ YouTube โดยตรง (ขนาดเล็กหน่อย แต่ชัวร์)
# 2. ถ้าโหลดไม่ได้ จะใช้ไอคอนของ Browser แทน
$IconUrl = "https://www.youtube.com/favicon.ico" 

try {
    # สั่งให้รองรับ TLS 1.2 (เผื่อ Windows เวอร์ชั่นเก่าโหลดไม่ได้)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # ดาวน์โหลดไฟล์
    Invoke-WebRequest -Uri $IconUrl -OutFile $IconPath -UseBasicParsing -ErrorAction Stop
    Write-Host "Icon downloaded successfully." -ForegroundColor Green
} catch {
    Write-Warning "Failed to download icon. Error details below:"
    Write-Warning $_.Exception.Message
    Write-Warning "Using Browser icon as fallback."
    $IconPath = $BrowserPath
}

# --- 4. สร้าง Shortcut ---
Write-Host "Creating Desktop Shortcut..." -ForegroundColor Cyan
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    
    $Shortcut.TargetPath = $BrowserPath
    $Shortcut.Arguments = "--user-data-dir=""$ProfileDir"" --app=https://www.youtube.com/tv --disable-features=CalculateNativeWinOcclusion --user-agent=""$UserAgent"""
    $Shortcut.IconLocation = $IconPath
    $Shortcut.Description = "YouTube on TV ($BrowserName)"
    $Shortcut.Save()
    
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Success! Shortcut created on Desktop." -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
} catch {
    Write-Error "Failed to create shortcut: $($_.Exception.Message)"
}

Start-Sleep -Seconds 2
