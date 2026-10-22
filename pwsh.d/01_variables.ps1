## Loaded by profile.ps1 pwsh.d loader. General environment variables.
## (Loader-critical vars -- PDOTDIR/PDOTDDIR/POWERSHELLCONFIGFILE -- stay in profile.ps1.)
##
## User-overridable settings are written to $global: so that (a) a value set
## earlier in powershell-config.ps1 wins, and (b) they refresh on an in-place
## 'reload'/'ez'. Pattern: $global:X = $X ?? <default>  (existing value wins).

###{{{ VARIABLES

$XDG_CONFIG_HOME = "${HOME}\.config"       ## (Windows default: $env:LOCALAPPDATA)
$XDG_DATA_HOME   = "$env:LOCALAPPDATA"
$DOTFILES        = "${HOME}\.dotfiles"

## Editor used by the `e` function. Default notepad.exe (ships with Windows);
## override in powershell-config.ps1 (e.g. code, nvim, kiro).
$global:EDITOR = $EDITOR ?? 'notepad.exe'

## Pager used by functions that page output (e.g. `cht`, PsReadLineVIExtension).
## Override with a plain $PAGER in powershell-config.ps1 (same style as $EDITOR);
## we export it to $env:PAGER, which is what the consumers actually read.
## Default 'less -FRX' (quit if one screen, raw ANSI colors, no screen clear)
## when less is on PATH; left unset otherwise (consumers fall back on their own).
$global:PAGER = $PAGER ?? $(if (Get-Command less -ErrorAction Ignore) { 'less -FRX' })
$env:PAGER    = $PAGER

$HISTFILE = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\$($host.Name)_history.txt"

## git config paths (local repo config vs the global ~/.config/git/config)
$GIT_CONFIG        = "${XDG_CONFIG_HOME}\git\config"
$GIT_CONFIG_GLOBAL = "${XDG_CONFIG_HOME}\git\config"

$WINDOWSTERMINAL_SETTINGS_FILE_PATH = "${XDG_DATA_HOME}\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$PowerCLI_Config_Dir = "$env:APPDATA\VMWare\PowerCLI"
$VMWare_Config_Dir   = "$env:APPDATA\VMWare"

$PSVersion = $PSVersionTable.PSVersion.Major
$USER      = $env:USERNAME
$HOSTNAME  = $env:COMPUTERNAME

## Transcript preferences (consumed by Start_PSTranscript). Overridable.
$global:PS_TRANSCRIPT_ENABLED = $PS_TRANSCRIPT_ENABLED ?? $true
$global:PS_TRANSCRIPT_DIR     = $PS_TRANSCRIPT_DIR     ?? "$XDG_DATA_HOME\PowerShell\Transcripts"
## Max transcript log files to keep (oldest are pruned). Set 0 to disable pruning.
$global:PS_TRANSCRIPT_MAX     = $PS_TRANSCRIPT_MAX     ?? 50

## Show ASCII art banner at startup (used by 10_ascii_art.ps1). Overridable.
$global:ShowStartupArt = $ShowStartupArt ?? $true

## Show the "Loading Modules: ..." line at startup. Read in profile.ps1 (before
## fragments load), so set it in powershell-config.ps1 to override. Default $true.
# $ShowModuleLoad = $true

###}}} END VARIABLES
