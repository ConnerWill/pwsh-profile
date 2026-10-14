## Loaded by profile.ps1 pwsh.d loader. Split from the old 03/05_functions.ps1.

###{{{ PACKAGE / MODULE SEARCH FUNCTIONS

Function yays(){
  [CmdletBinding()]
  Param(
    [Parameter(
      Position = 0,
      ValueFromPipeline = $true,
      ValueFromRemainingArguments = $true,
      Mandatory = $true
    )]
    [string]$SearchQuery
  )
  If ($SearchQuery -eq $null){
    Return
  }
  Else {
    Find-Module -Filter $SearchQuery                              `
      | Select-Object -Property Rank,Name,Description,Properties  `
        | Format-Table -AutoSize -Wrap
  }
}

#####################################################
#   Search for PS Modules In A Less Frustrating Way.
#####################################################

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

Function Instort-Module(){
	$ModuleToInstall = Read-Host "Enter Module Name To Install and Import   "
	Write-Host "Installing Module:  $ModuleToInstall ..." -ForegroundColor Yellow
	Install-Module -Name $ModuleToInstall -Force -Verbose -Confirm
	Write-Host "Importing Module:  $ModuleToInstall ..." -ForegroundColor Yellow
	Import-Module -Name $ModuleToInstall -Verbose
 	Get-Command -Module $ModuleToInstall
	Write-Host "DONE !" -ForegroundColor Green
}

###}}} END PACKAGE / MODULE SEARCH FUNCTIONS
