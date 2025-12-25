# =========================================================
#  FILE: inst_09.ps1 (WinRAR - Standalone with Auto 7-Zip)
# =========================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [CONFIG]
$GDriveID = "1VXYQKoo56m3vt4n4IhkPCQ6DpBVCCcYf" 
$Password = "ITG2"

$zipFile = "$env:TEMP\WinRAR7.20B3x64.rar"
$extractDir = "$env:TEMP\WinRAR7.20B3x64_Extract"
$aria2 = "$env:TEMP\aria2c.exe"
$tempResponse = "$env:TEMP\gdrive_probe.tmp"

# -----------------------------------------------------------
# STEP 0: 7-ZIP DEPENDENCY CHECK & AUTO-INSTALL
# -----------------------------------------------------------
Write-Host "[ INIT ] Checking dependencies..." -ForegroundColor Cyan

$7zPath = "$env:ProgramFiles\7-Zip\7z.exe"
if (-not (Test-Path $7zPath)) { $7zPath = "${env:ProgramFiles(x86)}\7-Zip\7z.exe" }

if (-not (Test-Path $7zPath)) {
    Write-Host "   >> 7-Zip not found. Auto-installing..." -ForegroundColor Yellow
    
    # Download 7-Zip
    $7zUrl = "https://www.7-zip.org/a/7z2408-x64.exe"
    $7zInstaller = "$env:TEMP\7z_setup.exe"
    
    try {
        Invoke-WebRequest $7zUrl -OutFile $7zInstaller -UseBasicParsing
        Start-Process -FilePath $7zInstaller -ArgumentList "/S" -Wait
        
        # Re-check path
        if (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") { 
            $7zPath = "$env:ProgramFiles\7-Zip\7z.exe"
            Write-Host "   >> 7-Zip installed successfully." -ForegroundColor Green
        } else {
             throw "Failed to install 7-Zip automatically."
        }
        Remove-Item $7zInstaller -Force
    } catch {
        throw "Could not download/install 7-Zip. Please install manually."
    }
} else {
    Write-Host "   >> 7-Zip is ready." -ForegroundColor Green
}

# -----------------------------------------------------------
# FUNCTION: GDrive Hybrid Download (Aria2 + Fallback)
# -----------------------------------------------------------
function Get-GDriveFile {
    param ($ID, $OutFile)
    $url = "https://drive.google.com/uc?export=download&id=$ID"
    Write-Host "[ CLOUD ] Probing Google Drive..." -ForegroundColor Cyan
    
    try {
        # 1. Probe & Parse
        Invoke-WebRequest -Uri $url -SessionVariable session -OutFile $tempResponse -UseBasicParsing
        
        $fileSize = (Get-Item $tempResponse).Length
        $finalUrl = $url 
        $useAria2 = $false
        
        if ($fileSize -lt 100000) {
            $content = Get-Content $tempResponse -Raw
            if ($content -match "download-form" -or $content -match "confirm=") {
                Write-Host "   >> Virus warning detected. Parsing token..." -ForegroundColor Magenta
                
                $actionUrl = "https://drive.usercontent.google.com/download"
                if ($content -match 'action="([^"]+)"') { $actionUrl = $matches[1] -replace '&amp;', '&' }
                
                $uuid = ""; $confirm = "t"
                if ($content -match 'name="uuid" value="([^"]+)"') { $uuid = $matches[1] }
                if ($content -match 'name="confirm" value="([^"]+)"') { $confirm = $matches[1] }
                
                if ($uuid) {
                    $finalUrl = "$actionUrl" + "?id=$ID&export=download&confirm=$confirm&uuid=$uuid"
                    $useAria2 = $true
                }
            }
        } else {
            Move-Item $tempResponse $OutFile -Force
            return 
        }
        
        # 2. Download Execution
        $ariaSuccess = $false
        if ($useAria2 -and (Test-Path $aria2)) {
            Write-Host "   >> Downloading via Aria2 (16 Connections)..." -ForegroundColor Cyan
            $cookieFile = "$env:TEMP\gdrive_cookies.txt"
            if (Test-Path $cookieFile) { Remove-Item $cookieFile -Force }
            
            # Save Cookies
            try {
                foreach ($cookie in $session.Cookies.GetCookies([Uri]$finalUrl)) {
                    $WinRAR = "$($cookie.Domain)`tTRUE`t$($cookie.Path)`t$($cookie.Secure.ToString().ToUpper())`t$($cookie.Expires.Ticks)`t$($cookie.Name)`t$($cookie.Value)"
                    Add-Content -Path $cookieFile -Value $WinRAR -ErrorAction SilentlyContinue
                }
            } catch {}

            $ariaArgs = @(
                "-q"
                "-x", "16", "-s", "16", "-j", "1",
                "--disable-ipv6=true",
                "--check-certificate=false",
                "--load-cookies=$cookieFile",
                "--user-agent=Mozilla/5.0",
                "-d", "$env:TEMP",
                "-o", "WinRARSetup.rar",
                "$finalUrl"
            )
            
            $procA = Start-Process -FilePath $aria2 -ArgumentList $ariaArgs -Wait -PassThru -NoNewWindow
            if ($procA.ExitCode -eq 0 -and (Test-Path $OutFile)) { $ariaSuccess = $true }
        }

        if (-not $ariaSuccess) {
            Write-Host "   >> Standard Download..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $finalUrl -WebSession $session -OutFile $OutFile -UseBasicParsing
        }
        
    } catch { throw "GDrive Error: $_" }
    finally { 
        if (Test-Path $tempResponse) { Remove-Item $tempResponse -Force }
        if (Test-Path "$env:TEMP\gdrive_cookies.txt") { Remove-Item "$env:TEMP\gdrive_cookies.txt" -Force }
    }
}

# -----------------------------------------------------------
# MAIN PROCESS
# -----------------------------------------------------------
try {
    # 1. Download WinRAR RAR
    if (Test-Path $zipFile) { Remove-Item $zipFile -Force }
    Get-GDriveFile -ID $GDriveID -OutFile $zipFile

    if ((Get-Item $zipFile).Length -lt 1000000) { throw "File too small." }

    # 2. Extract with 7-Zip
    Write-Host "[ WinRAR ] Extracting..." -ForegroundColor Yellow
    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    
    # ใช้ $7zPath ที่หาเจอตั้งแต่ต้น
    $7zArgs = "x ""$zipFile"" -o""$extractDir"" -p""$Password"" -y -bso0 -bsp0"
    $proc7z = Start-Process -FilePath $7zPath -ArgumentList $7zArgs -Wait -PassThru -NoNewWindow
    
    if ($proc7z.ExitCode -ne 0) { throw "Extraction Failed (Wrong Password?)" }

    # 3. Install & Kill
    $realInstaller = Get-ChildItem "$extractDir\*.exe" -Recurse | Select-Object -First 1
    if ($realInstaller) {
        Write-Host "[ WinRAR ] Installing..." -ForegroundColor Cyan
        $proc = Start-Process -FilePath $realInstaller.FullName -ArgumentList "/S" -PassThru
        
        $timeout = 0
        while (-not $proc.HasExited) {
            Start-Sleep -Seconds 2; $timeout++
            $WinRARApp = Get-Process "WinRAR" -ErrorAction SilentlyContinue
            if ($WinRARApp) {
                Write-Host "[ FIX ] Closing WinRAR Auto-Start..." -ForegroundColor Magenta
                $WinRARApp | Stop-Process -Force -ErrorAction SilentlyContinue
                if (-not $proc.HasExited) { $proc | Stop-Process -Force -ErrorAction SilentlyContinue }
                break
            }
            if ($timeout -ge 120) { $proc | Stop-Process -Force; break }
        }

        Write-Host "[ SUCCESS ] WinRAR PC Installed." -ForegroundColor Green
        
        # Cleanup ALL
        Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        throw "Installer not found."
    }

} catch {
    Write-Host "[ ERROR ] $_" -ForegroundColor Red
    exit 1
}
