## Update-Windows  --  from 24_functions_system.ps1 (one-file-per-function layout)

Function Update-Windows(){
	$SepLine = "===================================="
	clear
	Write-Host "Downloading Windows Update ..." -ForegroundColor Cyan
	Write-Host $SepLine -ForegroundColor Yellow
	Get-WindowsUpdate -Download -AcceptAll -IgnoreReboot -WindowsUpdate -Verbose
	Write-Host $SepLine -ForegroundColor Yellow
	Write-Host "Installing Windows Update ..." -ForegroundColor Cyan
	Write-Host $SepLine -ForegroundColor Yellow
	Install-WindowsUpdate -AcceptAll -Install -IgnoreReboot -WindowsUpdate -Verbose
	Write-Host $SepLine -ForegroundColor Yellow
	Write-Host "DONE" -BackgroundColor Green -ForegroundColor White
}
