# ---------------------------------------------------------
# การตั้งค่า (Configuration)
# ---------------------------------------------------------
# ชื่อไฟล์ Shortcut ที่คาดว่าจะเกิดขึ้น
$ShortcutPattern = "YouTube*.lnk"

# !!! แก้ไข: ใช้ User Agent เป็น Tizen 6.0 (Samsung TV รุ่นใหม่) เพื่อให้รองรับ YouTube TV ปัจจุบัน !!!
$UserAgentString = "Mozilla/5.0 (SMART-TV; LINUX; Tizen 6.0) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/4.0 Chrome/76.0.3809.146 TV Safari/537.36"

# หา path ของ Desktop ของผู้ใช้ปัจจุบัน
$DesktopPath = [System.Environment]::GetFolderPath('Desktop')

# ---------------------------------------------------------
# ขั้นตอนที่ 1: ตรวจสอบและเลือก Browser (Brave > Chrome)
# ---------------------------------------------------------
Write-Host "[STEP 1] Checking for compatible browsers..." -ForegroundColor Cyan

# กำหนด Path มาตรฐาน
$BravePath = "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe"
$ChromePath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
$SelectedBrowser = $null

# เลือก Brave ก่อน
if (Test-Path $BravePath) {
    $SelectedBrowser = $BravePath
    Write-Host "Found Browser: Brave" -ForegroundColor Green
}
# ถ้าไม่มี Brave ให้เอา Chrome
elseif (Test-Path $ChromePath) {
    $SelectedBrowser = $ChromePath
    Write-Host "Found Browser: Chrome" -ForegroundColor Green
}
else {
    Write-Host "Error: Neither Brave nor Chrome found." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# ---------------------------------------------------------
# ขั้นตอนที่ 2: เปิดลิงก์ด้วย Browser ที่เลือก
# ---------------------------------------------------------
Write-Host "`n[STEP 2] Launching YouTube TV..." -ForegroundColor Cyan
Start-Process -FilePath $SelectedBrowser -ArgumentList "https://youtube.com/tv"

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
    $FoundFile = Get-ChildItem -Path $DesktopPath -Filter $ShortcutPattern | Select-Object -First 1
    if ($null -eq $FoundFile) {
        Start-Sleep -Seconds 2
    }
}

# ---------------------------------------------------------
# ขั้นตอนที่ 4: ดักจับและแก้ไข (Intercept & Modify)
# ---------------------------------------------------------
Write-Host "`n[STEP 4] Shortcut detected: $($FoundFile.Name)" -ForegroundColor Green
Write-Host "Stealing and Modifying..." -ForegroundColor Cyan

Start-Sleep -Seconds 2

try {
    $WScript = New-Object -ComObject WScript.Shell
    $Shortcut = $WScript.CreateShortcut($FoundFile.FullName)

    Write-Host "Original Target: $($Shortcut.TargetPath)" -ForegroundColor Gray

    # แก้ Target: _proxy.exe -> .exe
    if ($Shortcut.TargetPath -match "_proxy.exe") {
        $Shortcut.TargetPath = $Shortcut.TargetPath -replace "_proxy.exe", ".exe"
    }

    # แก้ Arguments: เติม Tizen 6.0 UA
    # เช็คก่อนว่ามี UA หรือยัง จะได้ไม่เติมซ้ำ
    if ($Shortcut.Arguments -notmatch "user-agent") {
        $Shortcut.Arguments = "$($Shortcut.Arguments) --user-agent=`"$UserAgentString`""
    }

    $Shortcut.Save()

    Write-Host "Modified Target: $($Shortcut.TargetPath)" -ForegroundColor Green
    Write-Host "Modified Args:   $($Shortcut.Arguments)" -ForegroundColor Green
    Write-Host "`n[DONE] Shortcut hijacked successfully with Tizen 6.0!" -ForegroundColor Yellow
}
catch {
    Write-Host "Error modifying shortcut: $_" -ForegroundColor Red
}

Read-Host -Prompt "Press Enter to exit"
