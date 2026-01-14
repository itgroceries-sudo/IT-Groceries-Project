# ---------------------------------------------------------
# การตั้งค่า (Configuration)
# ---------------------------------------------------------
# ชื่อไฟล์ Shortcut ที่คาดว่าจะเกิดขึ้น
$ShortcutPattern = "YouTube*.lnk"

# User Agent สำหรับจำลอง Smart TV
$UserAgentString = "Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/4.0 Chrome/76.0.3809.146 TV Safari/537.36"

# หา path ของ Desktop ของผู้ใช้ปัจจุบัน
$DesktopPath = [System.Environment]::GetFolderPath('Desktop')

# ---------------------------------------------------------
# ขั้นตอนที่ 1: ตรวจสอบและเลือก Browser (Brave > Chrome)
# ---------------------------------------------------------
Write-Host "[STEP 1] Checking for compatible browsers..." -ForegroundColor Cyan

# กำหนด Path มาตรฐานของ Brave และ Chrome
$BravePath = "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe"
$ChromePath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
$SelectedBrowser = $null

# ตรวจสอบ: เลือก Brave ก่อน
if (Test-Path $BravePath) {
    $SelectedBrowser = $BravePath
    Write-Host "Found Browser: Brave" -ForegroundColor Green
}
# ตรวจสอบ: ถ้าไม่มี Brave ให้ดู Chrome
elseif (Test-Path $ChromePath) {
    $SelectedBrowser = $ChromePath
    Write-Host "Found Browser: Chrome" -ForegroundColor Green
}
else {
    # ถ้าไม่เจอทั้งคู่ แจ้งเตือนและจบการทำงาน
    Write-Host "Error: Neither Brave nor Chrome found in standard locations." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# ---------------------------------------------------------
# ขั้นตอนที่ 2: เปิดลิงก์ด้วย Browser ที่เลือก
# ---------------------------------------------------------
Write-Host "`n[STEP 2] Launching YouTube TV..." -ForegroundColor Cyan
Start-Process -FilePath $SelectedBrowser -ArgumentList "https://youtube.com/tv" --profile-directory=Default --app-id=agimnkijcaahngcdmfeangaknmldooml --user-agent="Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/4.0 Chrome/76.0.3809.146 TV Safari/537.36"

Write-Host "========================================================" -ForegroundColor Yellow
Write-Host " PLEASE INSTALL THE APP FROM BROWSER NOW!"
Write-Host " (Look for 'Install YouTube on TV' icon in address bar)"
Write-Host "========================================================" -ForegroundColor Yellow

# ---------------------------------------------------------
# ขั้นตอนที่ 3: รอไฟล์ .lnk (Watcher Loop)
# ---------------------------------------------------------
Write-Host "`n[STEP 3] Waiting for shortcut creation on Desktop..." -ForegroundColor Cyan

$FoundFile = $null
while ($null -eq $FoundFile) {
    # ค้นหาไฟล์ .lnk บน Desktop
    $FoundFile = Get-ChildItem -Path $DesktopPath -Filter $ShortcutPattern | Select-Object -First 1
    
    if ($null -eq $FoundFile) {
        # ถ้ายังไม่เจอ ให้รอ 2 วินาที
        Start-Sleep -Seconds 2
    }
}

# ---------------------------------------------------------
# ขั้นตอนที่ 4: ดักจับและแก้ไข (Intercept & Modify)
# ---------------------------------------------------------
Write-Host "`n[STEP 4] Shortcut detected: $($FoundFile.Name)" -ForegroundColor Green
Write-Host "Stealing and Modifying..." -ForegroundColor Cyan

# รอ 2 วินาทีเพื่อให้แน่ใจว่า Browser เขียนไฟล์เสร็จสมบูรณ์
Start-Sleep -Seconds 2

try {
    # สร้าง Object WScript.Shell เพื่อแก้ไข Shortcut
    $WScript = New-Object -ComObject WScript.Shell
    $Shortcut = $WScript.CreateShortcut($FoundFile.FullName)

    Write-Host "Original Target: $($Shortcut.TargetPath)" -ForegroundColor Gray

    # แก้ไข Target Path: เปลี่ยนจาก _proxy.exe เป็น .exe (รองรับทั้ง chrome_proxy และ brave_proxy)
    if ($Shortcut.TargetPath -match "_proxy.exe") {
        $Shortcut.TargetPath = $Shortcut.TargetPath -replace "_proxy.exe", ".exe"
    }

    # เติม User Agent ลงใน Arguments (ต่อท้ายของเดิม)
    if ($Shortcut.Arguments -notmatch "user-agent") {
        $Shortcut.Arguments = "$($Shortcut.Arguments) --user-agent=`"$UserAgentString`""
    }

    # บันทึกการเปลี่ยนแปลง
    $Shortcut.Save()

    Write-Host "Modified Target: $($Shortcut.TargetPath)" -ForegroundColor Green
    Write-Host "Modified Args:   $($Shortcut.Arguments)" -ForegroundColor Green
    Write-Host "`n[DONE] Shortcut hijacked successfully!" -ForegroundColor Yellow
}
catch {
    Write-Host "Error modifying shortcut: $_" -ForegroundColor Red
}

Read-Host -Prompt "Press Enter to exit"
