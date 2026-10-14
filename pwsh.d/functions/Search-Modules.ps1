## Search-Modules  --  from 23_functions_pkg.ps1 (one-file-per-function layout)

Function Search-Modules(){
	Clear-Host
	Write-Host $SepLine ##-ForegroundColor $SepLineColor
	# Prompt For Search String
	Write-Host "Enter PS Module Search String : " -NoNewline -ForegroundColor Magenta
	$modsearch = Read-Host
	Clear-Host
	Write-Host $SepLine ##-ForegroundColor $SepLineColor
	Write-Host "Searching Modules For *$modsearch* ..." -ForegroundColor DarkMagenta
	# Search For Modules Containing Entered String
	$foundModules = $(Find-Module -Name "*$modsearch*")
	# Format Results
	Clear-Host
	Write-Host $SepLine ##-ForegroundColor $SepLineColor
	$foundModules | Format-Table -Wrap
	Write-Host $SepLine ##-ForegroundColor $SepLineColor
	Write-Host "DONE" -BackgroundColor Green -ForegroundColor Black
	Write-Host "`nRun Command:  'Instort-Module'  To Install Modules" -ForegroundColor DarkBlue
}
