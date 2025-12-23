$url = "https://zoom.us/client/latest/ZoomInstallerFull.msi"
$fileName = "ZoomInstaller.msi"
$installArgs = "/qn /norestart ZoomAutoUpdate=true ZSSOHOST=us"
. "$env:TEMP\Master.ps1"