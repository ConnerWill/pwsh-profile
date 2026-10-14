## Instort-Module  --  from 23_functions_pkg.ps1 (one-file-per-function layout)

Function Instort-Module(){
	$ModuleToInstall = Read-Host "Enter Module Name To Install and Import   "
	Write-Host "Installing Module:  $ModuleToInstall ..." -ForegroundColor Yellow
	Install-Module -Name $ModuleToInstall -Force -Verbose -Confirm
	Write-Host "Importing Module:  $ModuleToInstall ..." -ForegroundColor Yellow
	Import-Module -Name $ModuleToInstall -Verbose
 	Get-Command -Module $ModuleToInstall
	Write-Host "DONE !" -ForegroundColor Green
}
