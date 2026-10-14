#Requires -Version 6.0
<#
.SYNOPSIS
  One-time setup for this PowerShell profile.
.DESCRIPTION
  Installs the modules this profile expects. Run this MANUALLY after cloning
  the dotfiles; it is intentionally NOT loaded on shell startup.

    pwsh -NoProfile -File "$HOME\Documents\PowerShell\install.ps1"
#>
[CmdletBinding()]
param(
  [switch]$Force
)

$Modules = @(
  'PSFunctionTools'
  'PSReadLine'
  'posh-git'
  'Plaster'
)

foreach ($m in $Modules) {
  if ($Force -or -not (Get-Module -ListAvailable -Name $m)) {
    Write-Host "Installing module: $m" -ForegroundColor Cyan
    try {
      Install-Module -Name $m -Scope CurrentUser -Force -AcceptLicense -ErrorAction Stop
    }
    catch {
      Write-Warning "Could not install '$m': $($_.Exception.Message)"
    }
  }
  else {
    Write-Host "Already installed: $m" -ForegroundColor DarkGray
  }
}

Write-Host "Setup complete." -ForegroundColor Green
