# =========================================================
#  FILE: inst_photoshop.ps1 (Self-Contained)
# =========================================================

# --- [PART 1] TOOL: GDrive Turbo Function (แปะไว้ตรงนี้เพื่อให้เรียกใช้ได้) ---
Function Download-GDriveTurbo {
    param (
        [Parameter(Mandatory=$true)] [string]$ID,
        [string]$DestDir = $env:TEMP,
        [string]$Aria2Path = "$env:TEMP\aria2c.exe"
    )
    $ErrorActionPreference = 'Stop'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProbeFile  = "$DestDir\gdrive_probe_$ID.tmp"
    $CookieFile = "$DestDir\gdrive_cookies_$ID.txt"

    try {
        Write-Host "[ CLOUD ] Analyzing Google Drive File..." -ForegroundColor Cyan
        $UrlBase = "https://drive.google.com/uc?export=download&id=$ID"
        $Response = Invoke-WebRequest -Uri $UrlBase -SessionVariable session -OutFile $ProbeFile -UseBasicParsing -PassThru
        $Content = [System.IO.File]::ReadAllText($ProbeFile, [System.Text.Encoding]::UTF8)
        
        $DetectedName = "GDrive_Download_$ID.dat"
        $FinalUrl = $UrlBase
        $foundName = $false

        if ($Response.Headers["Content-Disposition"] -match 'filename="?([^";]+)"?') {
            $DetectedName = $matches[1]; $foundName = $true
        }
        if (-not $foundName) {
            if ($Content -match "download-form" -or $Content -match "confirm=") {
                if ($Content -match 'class="uc-name-size"><a[^>]+>([^<]+)</a>') { $DetectedName = $matches[1].Trim(); $foundName = $true }
                elseif ($Content -match '(?i)<title>(.*?) - Google Drive</title>') { $DetectedName = $matches[1].Trim(); $foundName = $true }
                
                $confirm = "t"; if ($Content -match 'name="confirm" value="([^"]+)"') { $confirm = $matches[1] }
                $FinalUrl = "https://drive.usercontent.google.com/download?id=$ID&export=download&confirm=$confirm"
                if ($Content -match 'name="uuid" value="([^"]+)"') { $FinalUrl += "&uuid=$($matches[1])" }
            }
        }
        # Sanitizer
        $DetectedName = $DetectedName -replace '\s+', '_' -replace '[^a-zA-Z0-9._()\[\]-]', '' -replace '_{2,}', '_'
        Write-Host "[ CLOUD ] Target: $DetectedName" -ForegroundColor Green
        
        if (Test-Path $CookieFile) { Remove-Item $CookieFile -Force }
        foreach ($cookie in $session.Cookies.GetCookies([Uri]$FinalUrl)) {
            $line = "$($cookie.Domain)`tTRUE`t$($cookie.Path)`t$($cookie.Secure.ToString().ToUpper())`t$($cookie.Expires.Ticks)`t$($cookie.Name)`t$($cookie.Value)"
            Add-Content -Path $CookieFile -Value $line
        }
        if (-not (Test-Path $Aria2Path)) { 
             Write-Host " >> Installing engine..." -ForegroundColor Yellow
             Invoke-WebRequest "https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0-win-64bit-build1.zip" -OutFile "$env:TEMP\aria2.zip"
             Expand-Archive "$env:TEMP\aria2.zip" -DestinationPath "$env:TEMP\aria2_extract" -Force
             Move-Item "$env:TEMP\aria2_extract\aria2-1.36.0-win-64bit-build1\aria2c.exe" $Aria2Path -Force; Remove-Item "$env:TEMP\aria2.zip", "$env:TEMP\aria2_extract" -Recurse -Force
        }
        $FullSavePath = "$DestDir\$DetectedName"
        if (Test-Path $FullSavePath) { Remove-Item $FullSavePath -Force }
        Write-Host " >> Downloading..." -ForegroundColor Yellow
        $AriaArgs = @("-x", "16", "-s", "16", "-j", "1", "-k", "1M", "--file-allocation=none", "--console-log-level=error", "--disable-ipv6=true", "--check-certificate=false", "--load-cookies=$CookieFile", "--user-agent=Mozilla/5.0", "-d", $DestDir, "-o", $DetectedName, "$FinalUrl")
        $proc = Start-Process -FilePath $Aria2Path -ArgumentList $AriaArgs -Wait -PassThru -NoNewWindow
        if ($proc.ExitCode -ne 0) { throw "Download Failed" }
        if (-not (Test-Path $FullSavePath)) { throw "File not found" }
        return $FullSavePath
    } catch { throw } finally { if (Test-Path $ProbeFile) { Remove-Item $ProbeFile -Force -ErrorAction SilentlyContinue }; if (Test-Path $CookieFile) { Remove-Item $CookieFile -Force -ErrorAction SilentlyContinue } }
}

# --- [PART 2] INSTALLER LOGIC (ส่วนติดตั้งจริง) ---

# 1. กำหนดค่า (Config)
$MyID = "1n6ORbTF9mVV7u2d4iaZevaS5kITv_Vpv"  # <--- ID ไฟล์ Photoshop
$InstallPath = "C:\Program Files\Adobe"      # <--- ที่ที่จะลงโปรแกรม

try {
    # 2. เรียกใช้ฟังก์ชัน (ตอนนี้รู้จักกันแล้ว เพราะอยู่ในไฟล์เดียวกัน)
    $DownloadedFile = Download-GDriveTurbo -ID $MyID

    # 3. สั่งแตกไฟล์ / ติดตั้ง
    Write-Host " >> Extracting file..." -ForegroundColor Yellow
    
    # ตรวจสอบว่ามี 7-Zip ไหม (ถ้าไม่มีให้ใช้ WinRAR หรือตัวอื่นแทน)
    # สมมติใช้ 7-Zip ที่อยู่ใน Path หรือ Temp
    if (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") {
        & "$env:ProgramFiles\7-Zip\7z.exe" x "$DownloadedFile" -o"$InstallPath" -y
    } else {
        # ถ้าไม่มี 7-Zip ในเครื่อง อาจจะต้องโหลด 7z.exe มาก่อน หรือใช้ Expand-Archive (แต่ใช้กับ .rar ไม่ได้)
        Write-Host " [WARN] 7-Zip not found! Cannot extract .rar automatically." -ForegroundColor Red
        Write-Host " File is saved at: $DownloadedFile" -ForegroundColor Yellow
        Invoke-Item $DownloadedFile # เปิดไฟล์ให้ User กดเอง
    }

    Write-Host " >> Installation Complete!" -ForegroundColor Green

} catch {
    Write-Host " [ERROR] $_" -ForegroundColor Red
    Read-Host "Press ENTER to exit..."
}
