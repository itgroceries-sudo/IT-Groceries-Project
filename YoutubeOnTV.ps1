<# :
@echo off
:: ---------------------------------------------------------
:: Batch Wrapper (หัวเชื้อ)
:: ---------------------------------------------------------
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content '%~f0') -join \"`n\")"
goto :EOF
: #>

# ---------------------------------------------------------
# PowerShell Script (ไส้ใน)
# ---------------------------------------------------------

# --- CONFIGURATION ---
# เราจะหา Shortcut ชื่อ YouTube (ที่ได้จากการ Install หน้าเว็บปกติ)
$ShortcutPattern = "YouTube*.lnk"
# ชื่อใหม่ที่ต้องการ
$NewShortcutName = "Youtube On TV.lnk"

# LG WebOS User Agent (เสถียรสุด)
$UserAgentString = "Mozilla/5.0 (Web0S; Linux/SmartTV) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.5735.199 Safari/537.36 WebAppManager"
$ForceURL = "https://youtube.com/tv"
$DesktopPath = [System.Environment]::GetFolderPath('Desktop')

# --- STEP 1: หา Browser ---
Write-Host "[STEP 1] Checking Browsers..." -ForegroundColor Cyan
$BravePath = "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe"
$ChromePath = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
$SelectedBrowser = $null

if (Test-Path $BravePath) { $SelectedBrowser = $BravePath; Write-Host "Found: Brave" -ForegroundColor Green }
elseif (Test-Path $ChromePath) { $SelectedBrowser = $ChromePath; Write-Host "Found: Chrome" -ForegroundColor Green }
else { Write-Host "Error: No Browser Found." -ForegroundColor Red; Read-Host "Enter to exit"; exit }

# --- STEP 2: เปิดเว็บ YouTube ปกติ (เพื่อให้มีปุ่ม Install) ---
Write-Host "`n[STEP 2] Launching YouTube Desktop..." -ForegroundColor Cyan
Start-Process -FilePath $SelectedBrowser -ArgumentList "https://www.youtube.com"

Write-Host "========================================================" -ForegroundColor Yellow
Write-Host " ACTION REQUIRED: "
Write-Host " 1. Wait for YouTube to load."
Write-Host " 2. Click 'Install' icon in the address bar."
Write-Host " 3. Close the new app window once it opens."
Write-Host "========================================================" -ForegroundColor Yellow

# --- STEP 3: รอ Shortcut ---
Write-Host "`n[STEP 3] Waiting for shortcut..." -ForegroundColor Cyan
$FoundFile = $null
while ($null -eq $FoundFile) {
    # กรองเอาเฉพาะไฟล์ที่ยังไม่ใช่ชื่อใหม่ (กันมันไปจับตัวที่เราแก้เสร็จแล้ว)
    $FoundFile = Get-ChildItem -Path $DesktopPath -Filter $ShortcutPattern | Where-Object { $_.Name -ne $NewShortcutName } | Select-Object -First 1
    if ($null -eq $FoundFile) { Start-Sleep -Seconds 2 }
}

# --- STEP 4: เปลี่ยนชื่อและแก้ไข (Rename & Modify) ---
Write-Host "`n[STEP 4] Processing Shortcut..." -ForegroundColor Cyan
Start-Sleep -Seconds 2

try {
    # 4.1 เปลี่ยนชื่อไฟล์ (Rename)
    $NewFullPath = Join-Path $DesktopPath $NewShortcutName
    
    # ถ้ามีไฟล์ชื่อซ้ำอยู่แล้ว ให้ลบทิ้งก่อน
    if (Test-Path $NewFullPath) { Remove-Item $NewFullPath -Force }
    
    Rename-Item -Path $FoundFile.FullName -NewName $NewShortcutName
    Write-Host "Renamed to: $NewShortcutName" -ForegroundColor Green
    
    # 4.2 โหลด Shortcut ตัวใหม่มาแก้
    $WScript = New-Object -ComObject WScript.Shell
    $Shortcut = $WScript.CreateShortcut($NewFullPath)
    
    $OldTarget = $Shortcut.TargetPath
    Write-Host "Original Target: $OldTarget" -ForegroundColor Gray
    
    # 4.3 แก้ Target (Brave/Chrome Proxy -> .exe)
    $NewTarget = $OldTarget
    if ($OldTarget -match "brave_proxy.exe") {
        $NewTarget = $OldTarget -replace "brave_proxy.exe", "brave.exe"
    } elseif ($OldTarget -match "chrome_proxy.exe") {
        $NewTarget = $OldTarget -replace "chrome_proxy.exe", "chrome.exe"
    } elseif ($OldTarget -match "_proxy.exe") {
        $NewTarget = $OldTarget -replace "_proxy.exe", ".exe"
    }

    # ตรวจสอบว่าไฟล์ .exe มีจริงไหม
    if (Test-Path $NewTarget) {
        $Shortcut.TargetPath = $NewTarget
    } else {
        Write-Host "Warning: Target not found, using detected browser path." -ForegroundColor Yellow
        $Shortcut.TargetPath = $SelectedBrowser
    }

    # 4.4 แก้ Arguments (Force TV URL + UA)
    # ลบ --app-id ทิ้ง เพราะมันเป็นของหน้า Desktop
    $NewArgs = "--app=$ForceURL --user-agent=`"$UserAgentString`" --start-maximized"
    
    # เก็บ Profile เดิมไว้
    if ($Shortcut.Arguments -match "(--profile-directory=[^ ]+)") {
        $ProfileArg = $matches[1]
        $NewArgs = "$ProfileArg $NewArgs"
    }

    $Shortcut.Arguments = $NewArgs
    $Shortcut.Save()

    Write-Host "------------------------------------------------" 
    Write-Host "COMPLETED!" -ForegroundColor Yellow
    Write-Host "File:   $NewShortcutName"
    Write-Host "Mode:   TV Interface (Forced)"
    Write-Host "Browser: $(Split-Path $Shortcut.TargetPath -Leaf)"
    Write-Host "------------------------------------------------" 
    Write-Host "`n[SUCCESS] Setup finished." -ForegroundColor Green
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Read-Host -Prompt "Press Enter to exit"
