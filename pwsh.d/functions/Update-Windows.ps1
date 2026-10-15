## Update-Windows  --  from 24_functions_system.ps1 (one-file-per-function layout)

Function Update-Windows(){
	<#
	.SYNOPSIS
	  Download and install all available Windows Updates.
	.DESCRIPTION
	  Clears the screen, then uses the PSWindowsUpdate module to download every
	  available update and install it, accepting all and ignoring reboots so the
	  run doesn't restart the machine on you. Requires the PSWindowsUpdate module
	  and an elevated session. Windows-only.
	.EXAMPLE
	  Update-Windows
	  Download and install all pending updates (no automatic reboot).
	#>
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
