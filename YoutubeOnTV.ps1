# ==========================================
# YouTube on TV Installer (Embedded Icon)
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
if (-not (Test-Path $ProfileDir)) { New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null }

# --- 3. สร้างไฟล์ไอคอนจาก Base64 (ไม่ต้องโหลด) ---
Write-Host "Generating Icon..." -ForegroundColor Cyan
# นี่คือรหัสรูปภาพไอคอน YouTube (แปลงมาให้แล้ว)
$Base64Icon = "AAABAAAAEAgAAAEAIACICQAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAkAABXfAAAV3wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAL+/v//p6en/6enp/+np6f/p6en/6enp/+np6f/p6en/6enp/+np6f/p6en/v7+//wAAAAAAAAAAAAAAAAAAAAAA6enp//f39//39/f/9/f3//f39//39/f/9/f3//f39//39/f/9/f3/+np6f8AAAAAAAAAAAAAAAAAAAAAAL+/v//39/f/9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39//39/f/v7+//wAAAAAAAAAAAAAAAKqqqv/p6en/9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39//39/f/6enp/6qqqv8AAAAAAAAAAAAAAAC/v7//9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39/+/v7//AAAAAAAAAAAAAAAAv7+//+np6f/39/f/9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39//p6en/v7+//wAAAAAAAAAAAAAAAL+/v//39/f/9/f3//f39/8zMzP/MzMz/zMzM/8zMzP/9/f3//f39//39/f/9/f3/7+/v/8AAAAAAAAAAAAAAAC/v7//9/f3//f39//39/f/MzMz/zMzM/8zMzP/MzMz//f39//39/f/9/f3//f39/+/v7//AAAAAAAAAAAAAAAAv7+//+np6f/39/f/9/f3/zMzM/8zMzP/MzMz/zMzM//39/f/9/f3//f39//p6en/v7+//wAAAAAAAAAAAAAAAL+/v//39/f/9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39//39/f/v7+//wAAAAAAAAAAAAAAAKqqqv/p6en/9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39//39/f/6enp/6qqqv8AAAAAAAAAAAAAAAC/v7//9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39//39/f/9/f3/+/v7//AAAAAAAAAAAAAAAAAAAAAADp6en/9/f3//f39//39/f/9/f3//f39//39/f/9/f3//f39//39/f/6enp/wAAAAAAAAAAAAAAAAAAAAAAv7+//+np6f/p6en/6enp/+np6f/p6en/6enp/+np6f/p6en/6enp/+np6f+/v7//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

# เขียนไฟล์ .ico ลงเครื่อง
try {
    $IconBytes = [System.Convert]::FromBase64String($Base64Icon)
    [System.IO.File]::WriteAllBytes($IconPath, $IconBytes)
} catch {
    Write-Warning "Failed to create icon file. Using browser default."
    $IconPath = $BrowserPath
}

# --- 4. สร้าง Shortcut ---
Write-Host "Creating Shortcut..." -ForegroundColor Cyan
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)

$Shortcut.TargetPath = $BrowserPath
$Shortcut.Arguments = "--user-data-dir=""$ProfileDir"" --app=https://www.youtube.com/tv --disable-features=CalculateNativeWinOcclusion --user-agent=""$UserAgent"""
$Shortcut.IconLocation = $IconPath
$Shortcut.Description = "YouTube on TV ($BrowserName)"
$Shortcut.Save()

Write-Host "Success! Shortcut created on Desktop." -ForegroundColor Green
Start-Sleep -Seconds 2
