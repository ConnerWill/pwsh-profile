## Loaded by profile.ps1 pwsh.d loader. Tab-completion integrations.

###{{{ COMPLETION

# Chocolatey tab-completion. See https://ch0.co/tab-completion
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

###}}} END COMPLETION
