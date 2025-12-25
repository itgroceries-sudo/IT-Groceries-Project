:: =========================================================
::  DATABASE: CATEGORIZED SLOT SYSTEM
:: =========================================================

:: --- [GROUP 1] BROWSERS (Slot 01-05) ---
set "SLOT_01=chrome"
set "SLOT_02=firefox"
set "SLOT_03=edge"
:: set "SLOT_04=brave"
:: set "SLOT_05=opera"
set "SLOT_04=photoshop"

:: --- [GROUP 2] COMMUNICATION (Slot 06-10) ---
set "SLOT_06=line"
set "SLOT_07=discord"
set "SLOT_08=zoom"
set "SLOT_09=teams"
:: set "SLOT_10=..."

:: --- [GROUP 3] MULTIMEDIA & OFFICE (Slot 11-15) ---
set "SLOT_11=vlc"
set "SLOT_12=potplayer"
set "SLOT_13=libreoffice"
set "SLOT_14=obs"
set "SLOT_15=reader"

:: --- [GROUP 4] UTILITIES & TOOLS (Slot 16-20) ---
set "SLOT_16=7zip"
set "SLOT_17=anydesk"
set "SLOT_18=winrar"
set "SLOT_19=cpuz"
set "SLOT_20=everything"

:: =========================================================
::  SOFTWARE DETAILS (ID MAPPING)
:: =========================================================

:: [Browsers]
set "Name_chrome=Google Chrome"
set "P64_chrome=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
set "P32_chrome=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"

set "Name_firefox=Mozilla Firefox"
set "P64_firefox=%ProgramFiles%\Mozilla Firefox\firefox.exe"
set "P32_firefox=%ProgramFiles(x86)%\Mozilla Firefox\firefox.exe"

set "Name_edge=Microsoft Edge"
set "P64_edge=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"

set "Name_photoshop=PhotoShop 2026"

:: [Communication]
set "Name_line=LINE PC"
set "P64_line=%LocalAppData%\LINE\bin\LineLauncher.exe"

set "Name_discord=Discord"
set "P64_discord=%LocalAppData%\Discord\Update.exe"

set "Name_zoom=Zoom Meeting"
set "P64_zoom=%AppData%\Zoom\bin\Zoom.exe"

:: [Multimedia]
set "Name_vlc=VLC Media Player"
set "P64_vlc=%ProgramFiles%\VideoLAN\VLC\vlc.exe"

set "Name_potplayer=PotPlayer"
set "P64_potplayer=%ProgramFiles%\DAUM\PotPlayer\PotPlayerMini64.exe"

set "Name_libreoffice=LibreOffice"
set "P64_libreoffice=%ProgramFiles%\LibreOffice\program\soffice.exe"

:: [Tools]
set "Name_7zip=7-Zip Archiver"
set "P64_7zip=%ProgramFiles%\7-Zip\7z.exe"

set "Name_anydesk=AnyDesk Remote"
set "P64_anydesk=%ProgramFiles(x86)%\AnyDesk\AnyDesk.exe"

set "Name_cpuz=CPU-Z System Info"
set "P64_cpuz=%ProgramFiles%\CPUID\CPU-Z\cpuz.exe"


set "Name_teams=Microsoft Teams"


