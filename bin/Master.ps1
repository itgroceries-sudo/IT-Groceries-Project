# =========================================================
#  FILE: Master.ps1 (The Engine v4.0 - Ultimate Edition)
#  Enhanced by IT Groceries: IPv6 Disable, No Alloc, Anti-Rename
# =========================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# รับตัวแปรจากภายนอก: $url, $fileName, $installArgs
$dest = "$env:TEMP\$fileName"
$aria2 = "$env:TEMP\aria2c.exe"

# =========================================================
#  [CONFIG] ARIA2 ARGUMENTS (THE SECRET SAUCE)
# =========================================================
# ชุดคำสั่งมาตรฐาน (Base Args) สำหรับทุกการดาวน์โหลด
$AriaBaseArgs = @(
    "--disable-ipv6=true",        # ปิด IPv6 (แก้ปัญหาเน็ตบางค่าย/VPN)
    "--check-certificate=false",  # ไม่สน SSL (แก้ปัญหาเครื่องเก่า)
    "--file-allocation=none",     # ไม่ต้องจองพื้นที่ (เริ่มโหลดทันที)
    "--auto-file-renaming=false", # ห้ามเปลี่ยนชื่อไฟล์เอง (กันชื่อเพี้ยน)
    "--console-log-level=warn",   # ลดข้อความรกหน้าจอ
    "--user-agent=Mozilla/5.0",   # ปลอมตัวเป็น Browser
    "-j", "1",                    # 1 Concurrent Download
    "-d", "$env:TEMP",            # ปลายทาง
    "-o", "$fileName"             # ชื่อไฟล์
)

try {
    # ---------------------------------------------------------
    # 1. DOWNLOAD PHASE (Smart Logic: 16 -> 8 -> IWR)
    # ---------------------------------------------------------
    Write-Host "[ CLOUD ] Downloading $fileName..." -ForegroundColor Cyan
    
    # ถ้ามี Aria2 ให้เริ่มกระบวนการ Turbo
    if ($env:UseAria2 -eq "1" -and (Test-Path $aria2)) { 
        
        # [Attempt 1] High Speed (16 Connections)
        Write-Host "   >> Attempt 1: High Speed (16 Connections)..." -NoNewline -ForegroundColor Gray
        
        # รวม Args มาตรฐาน + Args ความเร็วสูง
        $Args16 = $AriaBaseArgs + @("-x", "16", "-s", "16", "$url")
        
        & $aria2 $Args16
        
        # ตรวจสอบผลลัพธ์
        if ($LASTEXITCODE -eq 0 -and (Test-Path $dest)) {
            Write-Host " [ OK ]" -ForegroundColor Green
        } else {
            # [Attempt 2] Standard Speed (8 Connections)
            Write-Host " [ FAIL ]" -ForegroundColor Red
            Write-Host "   >> Attempt 2: Standard Speed (8 Connections)..." -NoNewline -ForegroundColor Yellow
            
            # ลบไฟล์ขยะที่โหลดไม่เสร็จทิ้งก่อน
            if (Test-Path $dest) { Remove-Item $dest -Force }
            if (Test-Path "$dest.aria2") { Remove-Item "$dest.aria2" -Force }

            # รวม Args มาตรฐาน + Args ความเร็วปกติ
            $Args8 = $AriaBaseArgs + @("-x", "8", "-s", "8", "$url")

            & $aria2 $Args8
            
            if ($LASTEXITCODE -eq 0 -and (Test-Path $dest)) {
                Write-Host " [ OK ]" -ForegroundColor Green
            } else {
                # [Fail] ยอมแพ้แล้วใช้ตัวโหลดของ Windows
                Write-Host " [ FAIL ]" -ForegroundColor Red
                throw "Aria2 Failed. Switching to Basic Download."
            }
        }

    } else {
        # ถ้าไม่มี Aria2 ตั้งแต่ต้น ให้ข้ามไปใช้ Basic เลย
        throw "Aria2 not found. Using Basic Download."
    }

} catch {
    # [Attempt 3] (Last Resort) ใช้ Invoke-WebRequest (ช้าแต่ชัวร์)
    Write-Host "   >> Attempt 3: Basic Download (Invoke-WebRequest)..." -ForegroundColor Magenta
    try {
        if (Test-Path $dest) { Remove-Item $dest -Force }
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    } catch {
        Write-Host "[ FATAL ERROR ] Download Failed Completely." -ForegroundColor Red
        exit 1
    }
}

try {
    # ---------------------------------------------------------
    # 2. INSTALL PHASE
    # ---------------------------------------------------------
    if (Test-Path $dest) {
        Write-Host "[ CLOUD ] Installing..." -ForegroundColor Green
        
        if ($dest -like "*.msi") {
            $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$dest`" $installArgs" -Wait -PassThru
        } else {
            $proc = Start-Process -FilePath $dest -ArgumentList $installArgs -Wait -PassThru
        }
        
        # ---------------------------------------------------------
        # 3. VERIFY RESULT
        # ---------------------------------------------------------
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) { 
            Write-Host "[ SUCCESS ] Installation Complete." -ForegroundColor Green
        } else { 
            Write-Host "[ WARN ] Installer Exit Code: $($proc.ExitCode)" -ForegroundColor Yellow
        }
    } else {
        throw "File not found after download process."
    }

} catch {
    Write-Host "[ ERROR ] $_" -ForegroundColor Red
    exit 1

} finally {
    # ---------------------------------------------------------
    # 4. CLEANUP PHASE (ลบไฟล์ 100%)
    # ---------------------------------------------------------
    if (Test-Path $dest) {
        Write-Host "[ CLEANUP ] Removing installer..." -ForegroundColor Gray
        for ($i=1; $i -le 3; $i++) {
            try { Remove-Item $dest -Force -ErrorAction Stop; break } 
            catch { Start-Sleep 2 }
        }
    }
}
