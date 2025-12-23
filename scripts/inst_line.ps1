# =========================================================
#  FILE: inst_09.ps1 (LINE PC - GDrive Hybrid v3.1)
# =========================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [DEBUG] Version Check
Write-Host "`n [ VERSION ] v3.1 (Hybrid: Aria2 -> Auto Fallback)" -ForegroundColor Magenta
Write-Host " ----------------------------------------" -ForegroundColor Gray

# [CONFIG] ID ไฟล์ .rar
$GDriveID = "17pDr9jVgPWmLnnSAgXKXZw4c88fn0CRn" 
$Password = "ITG2"

$archiveFile = "$env:TEMP\LineSetup.rar"
$extractDir = "$env:TEMP\Line_Extract"
$tempResponse = "$env:TEMP\gdrive_probe.tmp"
$aria2 = "$env:TEMP\aria2c.exe"

# --- [FUNCTION] ระบบโหลดอัจฉริยะ (Aria2 -> Fallback to Native) ---
function Get-GDriveFile-Hybrid {
    param ($ID, $OutFile)
    
    $url = "https://drive.google.com/uc?export=download&id=$ID"
    Write-Host "[ CLOUD ] Probing Google Drive..." -ForegroundColor Cyan
    
    try {
        # 1. PROBE: ยิงไปดูลาดเลาก่อน (เก็บ Session/Cookie)
        Invoke-WebRequest -Uri $url -SessionVariable session -OutFile $tempResponse -UseBasicParsing
        
        $fileSize = (Get-Item $tempResponse).Length
        $finalUrl = $url 
        $useAria2 = $false
        
        # 2. ANALYZE: เช็คว่าติดหน้า Virus Scan ไหม
        if ($fileSize -lt 100000) {
            $content = Get-Content $tempResponse -Raw
            if ($content -match "download-form" -or $content -match "confirm=") {
                Write-Host "   >> Virus warning detected. Parsing token..." -ForegroundColor Magenta
                
                # แกะ URL Action (Domain)
                $actionUrl = "https://drive.usercontent.google.com/download"
                if ($content -match 'action="([^"]+)"') { 
                    $actionUrl = $matches[1] -replace '&amp;', '&' 
                }
                
                # แกะ Token
                $uuid = ""; $confirm = "t"
                if ($content -match 'name="uuid" value="([^"]+)"') { $uuid = $matches[1] }
                if ($content -match 'name="confirm" value="([^"]+)"') { $confirm = $matches[1] }
                
                if ($uuid) {
                    # สร้างลิงก์ตรง
                    $finalUrl = "$actionUrl" + "?id=$ID&export=download&confirm=$confirm&uuid=$uuid"
                    $useAria2 = $true
                    Write-Host "   >> Token Acquired." -ForegroundColor Yellow
                }
            }
        } else {
            # ถ้าได้ไฟล์เลย (ไม่ติด Scan) -> จบงาน (ใช้ไฟล์ที่ Probe มาเลย)
            Write-Host "   >> Direct download completed (Standard Speed)." -ForegroundColor Green
            Move-Item $tempResponse $OutFile -Force
            return 
        }
        
        # 3. ATTEMPT ARIA2 (ถ้ามี Token และมีโปรแกรม)
        $ariaSuccess = $false
        if ($useAria2 -and (Test-Path $aria2)) {
            Write-Host "   >> Attempting High-Speed Download (Aria2)..." -ForegroundColor Cyan
            
            # สร้างไฟล์ Cookie (รวมทุก Domain ที่เป็นไปได้)
            $cookieFile = "$env:TEMP\gdrive_cookies.txt"
            if (Test-Path $cookieFile) { Remove-Item $cookieFile -Force }
            
            $domains = @("https://drive.google.com", "https://drive.usercontent.google.com", "$finalUrl")
            foreach ($d in $domains) {
                try {
                    foreach ($cookie in $session.Cookies.GetCookies([Uri]$d)) {
                        $line = "$($cookie.Domain)`tTRUE`t$($cookie.Path)`t$($cookie.Secure.ToString().ToUpper())`t$($cookie.Expires.Ticks)`t$($cookie.Name)`t$($cookie.Value)"
                        Add-Content -Path $cookieFile -Value $line -ErrorAction SilentlyContinue
                    }
                } catch {}
            }

            # [FIXED SYNTAX] ใช้ Array Argument เพื่อความชัวร์ 100%
            $ariaArgs = @(
                "-x", "16", "-s", "16", "-j", "1",
                "--check-certificate=false",
                "--load-cookies=$cookieFile",
                "--user-agent=Mozilla/5.0",
                "-d", "$env:TEMP",
                "-o", "LineSetup.rar",
                "$finalUrl"
            )
            
            $procA = Start-Process -FilePath $aria2 -ArgumentList $ariaArgs -Wait -PassThru -NoNewWindow
            
            # ตรวจสอบผลงาน Aria2
            if ($procA.ExitCode -eq 0 -and (Test-Path $OutFile)) {
                if ((Get-Item $OutFile).Length -gt 100000) {
                    $ariaSuccess = $true
                    Write-Host "   >> Aria2 Success!" -ForegroundColor Green
                }
            }
        }

        # 4. FALLBACK (ถ้า Aria2 พลาด หรือไม่ได้ใช้ ให้ใช้ PowerShell โหลดต่อ)
        if (-not $ariaSuccess) {
            if ($useAria2) { Write-Host "   >> Aria2 failed. Switching to Standard Download..." -ForegroundColor Red }
            else { Write-Host "   >> Downloading..." -ForegroundColor Cyan }
            
            # ใช้ Session เดิมยิงโหลดเลย
            Invoke-WebRequest -Uri $finalUrl -WebSession $session -OutFile $OutFile -UseBasicParsing
            Write-Host "   >> Standard Download Success." -ForegroundColor Green
        }
        
    } catch {
        throw "GDrive Error: $_"
    } finally {
        if (Test-Path $tempResponse) { Remove-Item $tempResponse -Force }
        if (Test-Path "$env:TEMP\gdrive_cookies.txt") { Remove-Item "$env:TEMP\gdrive_cookies.txt" -Force }
    }
}
# -----------------------------------------------------------

try {
    # 1. DOWNLOAD
    if (Test-Path $archiveFile) { Remove-Item $archiveFile -Force }
    Get-GDriveFile-Hybrid -ID $GDriveID -OutFile $archiveFile

    if ((Get-Item $archiveFile).Length -lt 1000000) { throw "File too small (Download failed)." }

    # 2. EXTRACT
    $7z = "$env:ProgramFiles\7-Zip\7z.exe"
    if (-not (Test-Path $7z)) { $7z = "${env:ProgramFiles(x86)}\7-Zip\7z.exe" }
    if (-not (Test-Path $7z)) { throw "7-Zip not found. Please install Menu [01]." }

    Write-Host "[ LINE ] Extracting..." -ForegroundColor Yellow
    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    
    $7zArgs = "x ""$archiveFile"" -o""$extractDir"" -p""$Password"" -y"
    $proc7z = Start-Process -FilePath $7z -ArgumentList $7zArgs -Wait -PassThru -NoNewWindow
    if ($proc7z.ExitCode -ne 0) { throw "Extraction Failed (Wrong Password?)" }

    # 3. INSTALL
    $realInstaller = Get-ChildItem "$extractDir\*.exe" -Recurse | Select-Object -First 1
    if ($realInstaller) {
        Write-Host "[ LINE ] Installing..." -ForegroundColor Cyan
        $proc = Start-Process -FilePath $realInstaller.FullName -ArgumentList "/S" -PassThru
        
        $timeout = 0
        while (-not $proc.HasExited) {
            Start-Sleep -Seconds 2; $timeout++
            $lineApp = Get-Process "LINE" -ErrorAction SilentlyContinue
            if ($lineApp) {
                Write-Host "[ FIX ] Killing Auto-Start LINE..." -ForegroundColor Magenta
                $lineApp | Stop-Process -Force -ErrorAction SilentlyContinue
                if (-not $proc.HasExited) { $proc | Stop-Process -Force -ErrorAction SilentlyContinue }
                break
            }
            if ($timeout -ge 120) { $proc | Stop-Process -Force; break }
        }

        Write-Host "[ SUCCESS ] LINE PC Installed." -ForegroundColor Green
        Remove-Item $archiveFile -Force -ErrorAction SilentlyContinue
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        throw "Installer not found in archive."
    }

} catch {
    Write-Host "[ ERROR ] $_" -ForegroundColor Red
    if (Test-Path $archiveFile) { Remove-Item $archiveFile -Force -ErrorAction SilentlyContinue }
    exit 1
}