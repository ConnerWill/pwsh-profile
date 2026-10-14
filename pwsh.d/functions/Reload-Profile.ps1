## Reload-Profile  --  from 24_functions_system.ps1 (one-file-per-function layout)

Function Reload-Profile(){
  <#
  .SYNOPSIS
    Reload the PowerShell profile in the current session.
  .DESCRIPTION
    Re-sources the CurrentUserAllHosts profile (profile.ps1), which in turn
    re-runs the pwsh.d loader. Handy for testing profile changes without
    opening a new shell.
  .EXAMPLE
    Reload-Profile
  #>
  [CmdletBinding()]
  [Alias('reload','ez')]
  Param()
  $profilePath = $PROFILE.CurrentUserAllHosts
  if (Test-Path -Path $profilePath) {
    Write-Host "Reloading profile: $profilePath" -ForegroundColor Cyan
    . $profilePath
  }
  else {
    Write-Warning "Profile not found: $profilePath"
  }
}
