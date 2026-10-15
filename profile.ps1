#vim:fileencoding=utf-8:shiftwidth=2:softtabstop=2:expandtab:fileformat=unix:filetype=ps1:foldmethod=marker:foldmarker=###{{{,###}}}:foldminlines=10
##############################################################################
##  PowerShell 7 profile (CurrentUserAllHosts) -- minimal bootstrap.
##
##  This file only does what must happen before/around loading the config
##  fragments. All behavior (variables, functions, prompt, PSReadLine,
##  keybindings, completion) lives in pwsh.d/*.ps1, loaded in filename order.
##
##  See docs/README.md for the full layout.
##############################################################################

#Requires -Version 7.0

using namespace System.Management.Automation
using namespace System.Management.Automation.Language

##############################################################################
###{{{ BOOTSTRAP VARIABLES (needed by the loaders below)

$PDOTDIR  = Split-Path -Path $PROFILE.CurrentUserAllHosts
$PDOTDDIR = Join-Path $PDOTDIR "pwsh.d"
$POWERSHELLCONFIGFILE = Join-Path $PDOTDIR "powershell-config.ps1"

## Optional machine-local overrides. Dot-sourced directly (NOT inside a
## function) so variables like $EDITOR land in the profile scope and are
## visible to the pwsh.d fragments.
if (Test-Path -Path $POWERSHELLCONFIGFILE){ . $POWERSHELLCONFIGFILE }

###}}} END BOOTSTRAP VARIABLES
##############################################################################

##############################################################################
###{{{ COLORS (single source of truth; used by helpers / prompt / loaders)

## ANSI color palette (single source of truth). $Colors.<Key> -> escape string.
if ($PSVersionTable.PSVersion.Major -ge 6){
  $Colors = @{
    Reset          = "`e[0m"
    Bold           = "`e[1m"
    Italic         = "`e[3m"
    Underline      = "`e[4m"
    Blink          = "`e[6m"
    White          = "`e[38;5;15m"
    Black          = "`e[38;5;0m"
    Red            = "`e[38;5;196m"
    Yellow         = "`e[38;5;190m"
    Green          = "`e[38;5;46m"
    Cyan           = "`e[38;5;87m"
    Blue           = "`e[38;5;33m"
    Magenta        = "`e[38;5;201m"
    Purple         = "`e[38;5;93m"
    CyanBright     = "`e[38;5;51m"
    Teal           = "`e[38;5;66m"
    Grey           = "`e[38;5;8m"
    Violet         = "`e[38;5;99m"
    Orange         = "`e[38;5;208m"
    BgWhite        = "`e[48;5;15m"
    BgBlack        = "`e[48;5;0m"
    BgRed          = "`e[48;5;196m"
    BgYellow       = "`e[48;5;190m"
    BgGreen        = "`e[48;5;46m"
    BgCyan         = "`e[48;5;87m"
    BgBlue         = "`e[48;5;33m"
    BgMagenta      = "`e[48;5;201m"
    BgPurple       = "`e[48;5;93m"
  }
}
###}}} END COLORS
##############################################################################

##############################################################################
###{{{ CORE HELPERS (is_admin + colored message helpers; used during load)

function is_admin {
    # Cross-platform elevation check. On Windows use the WindowsPrincipal API;
    # elsewhere (Linux/macOS) treat uid 0 (root) as elevated. Must never throw,
    # because the prompt calls this on every render -- an exception here makes
    # PowerShell fall back to the default 'PS>' prompt.
    try {
        if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
            $id = [Security.Principal.WindowsIdentity]::GetCurrent()
            return ([Security.Principal.WindowsPrincipal]$id).IsInRole(
                [Security.Principal.WindowsBuiltInRole]::Administrator)
        }
        else {
            return ((id -u) -eq 0)
        }
    }
    catch { return $false }
}

# messages
function abort($msg, [int] $exit_code=1) { write-host $msg -f red; exit $exit_code }
function error($msg){     Write-Output "$($Colors.BgRed)$($Colors.White)[ERROR]$($Colors.Reset):   $($Colors.Red)$msg$($Colors.Reset)"}
function warn($msg){     Write-Output "$($Colors.BgYellow)$($Colors.Red)[WARNING]$($Colors.Reset): $($Colors.Yellow)$msg$($Colors.Reset)"}
function info($msg){     Write-Output "$($Colors.BgBlue)$($Colors.White)[INFO]$($Colors.Reset):    $($Colors.Blue)$msg$($Colors.Reset)"}
function debug($msg){   Write-Output "$($Colors.BgCyan)$($Colors.Yellow)[DEBUG]$($Colors.Reset):   $($Colors.Cyan)$msg$($Colors.Reset)"}
function success($msg){ Write-Output "$($Colors.BgGreen)$($Colors.White)[SUCCESS]$($Colors.Reset): $($Colors.Cyan)$msg$($Colors.Reset)"}

###}}} END CORE HELPERS
##############################################################################

##############################################################################
###{{{ ASCII ART (shown first, before module loading)

## Source ascii-art.ps1 (defines $Art) and show a random banner. Printed here
## -- before modules -- so the art appears at the very top of startup.
## $ShowStartupArt defaults on; set it $false in powershell-config.ps1 to hide.
$__artFile = Join-Path $PDOTDIR 'ascii-art.ps1'
if (Test-Path -Path $__artFile) { . $__artFile }
$__showArt = if ($null -ne $ShowStartupArt) { [bool]$ShowStartupArt } else { $true }
if ($__showArt -and $Art -is [hashtable] -and $Art.Count -gt 0) {
  $__pick = $Art.Values | Get-Random
  $__artColor = Get-Random -Minimum 16 -Maximum 231
  Write-Output "`e[0;1;38;5;${__artColor}m$__pick`e[0m"
  Remove-Variable __pick, __artColor -ErrorAction Ignore
}
Remove-Variable __artFile, __showArt -ErrorAction Ignore

###}}} END ASCII ART
##############################################################################

##############################################################################
###{{{ MODULES

Function Invoke-LoadPowerShellModules(){
  ## Set $ShowModuleLoad = $false in powershell-config.ps1 to hide the
  ## "Loading Modules: ..." output at startup (modules still load silently).
  $showLoad = if ($null -ne $ShowModuleLoad) { [bool]$ShowModuleLoad } else { $true }

  ## Define modules to load
  ## NOTE: posh-git and Plaster were removed from startup load (nothing in
  ## this profile uses them; the git prompt is hand-rolled in 40_prompt.ps1).
  ## They remain available via the opt-in installer: install-pwshprofile.ps1
  If ($host.Name -eq 'ConsoleHost'){
    $ModulesArray = @(`
      "Get-ChildItemColor",
      "PSReadLine",
      "${PDOTDIR}\local-modules\PSReadLineViVisualMode\src\PSReadLineViVisualMode",
      "${PDOTDIR}\local-modules\pwsh-syntax-highlighting\syntax-highlighting.psm1",
      "${PDOTDIR}\local-modules\powershell-pathx\pathx.psm1"
    )

    ## Load Modules
    if ($showLoad) { [console]::Write("`e[0;4;38;5;93mLoading Modules`e[0m: ") }
    ForEach ($LoadModule in $ModulesArray){
      Try { Import-Module -Name $LoadModule -ErrorAction Stop 2>$null }
      Catch { if ($showLoad) { [console]::WriteLine("`n`e[0;38;5;196mUnable to load module: `e[0;1;38;5;190m$LoadModule`e[0m") }; continue }
      $LoadModule_BaseName = $null
      if (Test-Path -Path $LoadModule) { $LoadModule_BaseName = (Get-Item -Path $LoadModule).BaseName }
      $LoadModulesRandomColor = Get-Random -Min 1 -Max 230
      If ($null -ne $LoadModule_BaseName){
        $LoadModule=$LoadModule_BaseName
      }
      if ($showLoad) { [console]::Write(" `e[0;1;38;5;${LoadModulesRandomColor}m$LoadModule`e[0m") }
    }
    ## Terminate the "Loading Modules:" line so the host's
    ## "Loading personal and system profiles took ..." message lands on its own line.
    if ($showLoad) { [console]::WriteLine() }
  }
}; Invoke-LoadPowerShellModules

###}}} END MODULES
##############################################################################

##############################################################################
###{{{ LOAD pwsh.d FRAGMENTS

## Dot-source every pwsh.d/*.ps1 in filename order. Numeric prefixes set order.
if (Test-Path -Path $PDOTDDIR){
  ForEach ($pwshd_file in (Get-ChildItem -File -Path $PDOTDDIR -Filter '*.ps1' | Sort-Object Name)){
    try { . $pwshd_file.FullName }
    catch {
      error "Unable to load startup file: '$($pwshd_file.FullName)'"
      Write-Warning ("  -> {0} (line {1})" -f $_.Exception.Message, $_.InvocationInfo.ScriptLineNumber)
    }
  }
}

###}}} END LOAD pwsh.d FRAGMENTS
##############################################################################
