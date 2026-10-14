###{{{ MODULES
## Ensure optional modules are available WITHOUT reinstalling on every startup.
## This fragment is dot-sourced by profile.ps1 on each launch, so anything
## expensive (like Install-Module, which hits the PowerShell Gallery) must be
## guarded behind an existence check.

$EnsureModules = @(
  'PSFunctionTools'
)

foreach ($m in $EnsureModules) {
  if (-not (Get-Module -ListAvailable -Name $m)) {
    try {
      Install-Module -Name $m -Scope CurrentUser -Force -AcceptLicense -ErrorAction Stop
    }
    catch {
      Write-Warning "Could not install module '$m': $($_.Exception.Message)"
    }
  }
}
###}}} END MODULES
