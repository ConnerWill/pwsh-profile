## Loaded by profile.ps1 pwsh.d loader.
## PSReadLine OPTIONS/preferences (edit mode, prediction, history path, vi
## cursor). Key *bindings* live in 50_keybindings.ps1; this loads first so the
## edit mode is set before handlers register.

###{{{ PSREADLINE OPTIONS

##############################################################################
## EditMode: windows,(vi),emacs
$_Define_PSReadLineEditMode = "vi"
## If PSReadLineEditMode is not set, set it as vi
If ([string]::IsNullOrEmpty($_Define_PSReadLineEditMode)){ $_Define_PSReadLineEditMode = "vi" }
Set-PSReadLineOption -EditMode $_Define_PSReadLineEditMode

## Set Prediction Options
Set-PSReadLineOption -PredictionSource History

## Wire $HISTFILE into PSReadLine's history path (was previously defined but unused).
if ($HISTFILE) {
  $histDir = Split-Path -Path $HISTFILE -Parent
  if ($histDir -and -not (Test-Path -Path $histDir)) {
    New-Item -Path $histDir -ItemType Directory -Force | Out-Null
  }
  Set-PSReadLineOption -HistorySavePath $HISTFILE
}
#Set-PSReadLineOption -PredictionViewStyle ListView
##############################################################################



function OnViModeChange {
  if ($args[0] -eq 'Command') { Write-Host -NoNewLine "`e[1 q" } # Set the cursor to a blinking block.
  else { Write-Host -NoNewLine "`e[5 q" } # Set the cursor to a blinking line
}

###}}} END PSREADLINE OPTIONS
