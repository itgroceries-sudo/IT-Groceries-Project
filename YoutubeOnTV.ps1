# ==========================================
# YouTube on TV Installer (High-Res Edition)
# Created by: IT Groceries Shop
# ==========================================

Write-Host "Checking Browser Installation..." -ForegroundColor Cyan

# --- 1. ตรวจสอบ Browser ---
$BrowserPath = $null; $BrowserName = ""; $UserDataBase = ""
$BravePaths = @("$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe", "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe", "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe")
$ChromePaths = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe")

foreach ($path in $BravePaths) { if (Test-Path $path) { $BrowserPath = $path; $BrowserName = "Brave"; $UserDataBase = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"; break } }
if (-not $BrowserPath) { foreach ($path in $ChromePaths) { if (Test-Path $path) { $BrowserPath = $path; $BrowserName = "Chrome"; $UserDataBase = "$env:LOCALAPPDATA\Google\Chrome\User Data"; break } } }

if (-not $BrowserPath) { Write-Error "Error: No supported browser found."; Start-Sleep -Seconds 5; return }
Write-Host "Found Browser: $BrowserName" -ForegroundColor Green

# --- 2. ตั้งค่า Path ---
$AppName = "YouTube on TV"
$ProfileDir = "$UserDataBase\YouTubeTV_Mode"
$IconPath = "$ProfileDir\youtube_tv.ico"
$ShortcutPath = "$env:USERPROFILE\Desktop\$AppName.lnk"
$UserAgent = "Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/4.0 Chrome/76.0.3809.146 TV Safari/537.36"

if (-not (Test-Path $ProfileDir)) { New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null }

# --- 3. ดาวน์โหลดไอคอน (High-Res) ---
Write-Host "Downloading High-Res Icon..." -ForegroundColor Cyan

# URL นี้เป็นไฟล์ .ico ที่รวมหลายขนาดไว้ (ตั้งแต่ 16px ถึง 256px) ชัดแน่นอนครับ
$HiResIconUrl = "https://raw.githubusercontent.com/nancy-kataria/youtube-clone/gh-pages/Youtube.ico"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    # โหลดแบบ Force เขียนทับไฟล์เดิม (เผื่อไฟล์เดิมเป็นตัวไม่ชัด)
    Invoke-WebRequest -Uri $HiResIconUrl -OutFile $IconPath -UseBasicParsing -ErrorAction Stop
    Write-Host "Icon downloaded successfully." -ForegroundColor Green
} catch {
    Write-Warning "Failed to download High-Res icon. Using Browser icon."
    $IconPath = $BrowserPath
}

# --- 4. สร้าง Shortcut ---
Write-Host "Creating Desktop Shortcut..." -ForegroundColor Cyan
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)

$Shortcut.TargetPath = $BrowserPath
$Shortcut.Arguments = "--user-data-dir=""$ProfileDir"" --app=https://www.youtube.com/tv --disable-features=CalculateNativeWinOcclusion --user-agent=""$UserAgent"""
$Shortcut.IconLocation = $IconPath # ชี้ไปที่ไฟล์ที่เราเพิ่งโหลดมา
$Shortcut.Description = "YouTube on TV ($BrowserName)"
$Shortcut.Save()

Write-Host "==========================================" -ForegroundColor Green
Write-Host "Success! Shortcut created on Desktop." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Start-Sleep -Seconds 2
