@echo off
:: =========================================================
::  THEME MANAGER (Icon, Window, Colors)
::  Version: Cloud-Self-Fetch
:: =========================================================

:: 1. กำหนดขนาดหน้าต่าง
mode con: cols=120 lines=28

:: 2. สร้างรหัสสี (ESC Code)
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"

:: 3. นิยามตัวแปรสี
set "Reset=%ESC%[0m" & set "Bold=%ESC%[1m"
set "Hi_White=%ESC%[97m" & set "Hi_Cyan=%ESC%[96m" & set "Hi_Yellow=%ESC%[93m" & set "Hi_Green=%ESC%[92m"
set "Bg_Blue=%ESC%[44m" & set "Bg_Green=%ESC%[42m" & set "Bg_Red=%ESC%[41m"
set "Bg_Yellow=%ESC%[43m" & set "Bg_Cyan=%ESC%[46m" & set "Bg_Magenta=%ESC%[45m" & set "Bg_White=%ESC%[47m"
set "Black=%ESC%[30m" & set "Cyan=%ESC%[36m" & set "White=%ESC%[37m"

:: =========================================================
::  4. จัดการ ICON (AUTO DOWNLOAD)
:: =========================================================
set "ICON_URL=https://itgroceries.blogspot.com/favicon.ico"
set "ICON_FILE=%TEMP%\ITGBlog.ico"

:: 4.1 ถ้าไม่มีไฟล์ใน Temp ให้โหลดจาก Blogspot
if not exist "%ICON_FILE%" (
    powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%ICON_URL%' -OutFile '%ICON_FILE%' -UseBasicParsing } catch {}"
)

:: 4.2 ถ้ามีไฟล์แล้ว (หรือเพิ่งโหลดเสร็จ) ให้ตั้งค่า Icon
if exist "%ICON_FILE%" (
    powershell -Command ^
      "$d='[DllImport(\"user32.dll\")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);[DllImport(\"user32.dll\")] public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad);[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow();';" ^
      "$w=Add-Type -MemberDefinition $d -Name 'WinIcon' -Namespace Win32 -PassThru;" ^
      "$h=$w::GetConsoleWindow();" ^
      "$i=$w::LoadImage([IntPtr]::Zero, '%ICON_FILE%', 1, 0, 0, 0x10);" ^
      "if ($i -ne [IntPtr]::Zero) { $w::SendMessage($h, 0x80, [IntPtr]0, $i); $w::SendMessage($h, 0x80, [IntPtr]1, $i); }" >nul 2>&1
)

:: =========================================================
::  5. ล็อคหน้าต่าง (Fix Window)
:: =========================================================
powershell -Command ^
  "$u='[DllImport(\"user32.dll\")] public static extern int GetWindowLong(IntPtr h,int n);[DllImport(\"user32.dll\")] public static extern int SetWindowLong(IntPtr h,int n,int w);[DllImport(\"user32.dll\")] public static extern bool SetWindowPos(IntPtr h,IntPtr i,int x,int y,int cx,int cy,uint f);[DllImport(\"user32.dll\")] public static extern int DeleteMenu(IntPtr h,int n,int w);[DllImport(\"user32.dll\")] public static extern IntPtr GetSystemMenu(IntPtr h,bool b);[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow();';" ^
  "$t=Add-Type -MemberDefinition $u -Name 'Win32' -Namespace Win32 -PassThru;" ^
  "$h=$t::GetConsoleWindow();" ^
  "Add-Type -AssemblyName System.Windows.Forms;" ^
  "$s=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds;" ^
  "$x=($s.Width - (120*8))/2; $y=($s.Height - (38*18))/2;" ^
  "$t::SetWindowPos($h,0,$x,$y,0,0,0x41);" ^
  "$style=$t::GetWindowLong($h,-16);" ^
  "$t::SetWindowLong($h,-16,$style -band 0xFFFEFFFF);" ^
  "$m=$t::GetSystemMenu($h,$false);" ^
  "$t::DeleteMenu($m,0xF060,0);" >nul 2>&1

exit /b