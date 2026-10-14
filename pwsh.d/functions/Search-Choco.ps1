## Search-Choco  --  from 23_functions_pkg.ps1 (one-file-per-function layout)

Function Search-Choco(){
	Clear-Host
	Write-Host $SepLine #-ForegroundColor $SepLineColor
	# Prompt For Search String
	Write-Host "Enter String To Search Chocolatey : " -NoNewline -ForegroundColor Magenta
	$chocoSearchString = Read-Host
	Clear-Host
	Write-Host $SepLine #-ForegroundColor $SepLineColor
	Write-Host "Searching for Choco Packages Including '$chocoSearchString' ..." -ForegroundColor DarkMagenta
	$FoundChocoPackages = choco search $chocoSearchString --order-by-popularity --limit-output --detailed --not-broken  --page-size=25
	Clear-Host
	Write-Host $SepLine #-ForegroundColor $SepLineColor
	$FoundChocoPackages
	Write-Host $SepLine #-ForegroundColor $SepLineColor
	Write-Host "DONE" -BackgroundColor Green -ForegroundColor Black
	Write-Host "`nUse 'choco install <packagename>' to install packages." -ForegroundColor DarkBlue
}
