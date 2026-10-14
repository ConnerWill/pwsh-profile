## Search-Script  --  from 23_functions_pkg.ps1 (one-file-per-function layout)

Function Search-Script(){
	Clear-Host
	Write-Host $SepLine #-ForegroundColor $SepLineColor
	# Prompt For Search String
	Write-Host "Enter Script Search String : " -NoNewline -ForegroundColor Magenta
	$modsearch = Read-Host
	Clear-Host
	Write-Host $SepLine #-ForegroundColor $SepLineColor
	Write-Host "Searching Scripts For *$modsearch* ..." -ForegroundColor DarkMagenta
	# Search For Modules Containing Entered String
	$foundModules = $(Find-Script -Name "*$modsearch*")
	# Format Results
	Write-Host $SepLine #-ForegroundColor $SepLineColor
	$foundModules | Format-Table -Wrap
	Write-Host $SepLine #-ForegroundColor $SepLineColor
	Write-Host "DONE" -BackgroundColor Green -ForegroundColor Black
	#Write-Host "`nRun Command:  'Instort-Module'  To Install Modules" -ForegroundColor DarkBlue
}
