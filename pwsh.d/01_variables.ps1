## Loaded by profile.ps1 pwsh.d loader. General environment variables.
## (Loader-critical vars -- PDOTDIR/PDOTDDIR/POWERSHELLCONFIGFILE -- stay in profile.ps1.)
##
## User-overridable settings use ??= so a value already set in
## powershell-config.ps1 (dot-sourced earlier) wins. Hard '=' assignments are
## fixed defaults.

###{{{ VARIABLES

$XDG_CONFIG_HOME = "${HOME}\.config"       ## (Windows default: $env:LOCALAPPDATA)
$XDG_DATA_HOME   = "$env:LOCALAPPDATA"
$DOTFILES        = "${HOME}\.dotfiles"

## Editor used by the `e` function. Override in powershell-config.ps1.
$EDITOR ??= 'notepad++.exe'

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
$PS_TRANSCRIPT_ENABLED ??= $True
$PS_TRANSCRIPT_DIR     ??= "$XDG_DATA_HOME\PowerShell\Transcripts"
## Max transcript log files to keep (oldest are pruned). Set 0 to disable pruning.
$PS_TRANSCRIPT_MAX     ??= 50

## Show ASCII art banner at startup (used by 10_ascii_art.ps1). Overridable.
$ShowStartupArt ??= $true

###}}} END VARIABLES
