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

## Optional machine-local overrides, dot-sourced early if present.
## Optional machine-local overrides. Dot-sourced directly (NOT inside a
## function) so variables like $EDITOR land in the profile scope and are
## visible to the pwsh.d fragments. (A function would trap them in its local
## scope and they'd vanish on return.)
if (Test-Path -Path $POWERSHELLCONFIGFILE){ . $POWERSHELLCONFIGFILE }

###}}} END BOOTSTRAP VARIABLES
##############################################################################

##############################################################################
###{{{ COLORS (used by the message helpers and module/pwsh.d loaders below)

if ($PSVersionTable.PSVersion.Major -ge 6){
#$ColorTable = @{
    $color_reset = "`e[0m"
    $color_bold = "`e[1m"
    $color_italic = "`e[3m"
    $color_underline = "`e[4m"
    $color_blink = "`e[6m"

    $color_white = "`e[38;5;15m"
    $color_black = "`e[38;5;0m"
    $color_red = "`e[38;5;196m"
    $color_yellow = "`e[38;5;190m"
    $color_green = "`e[38;5;46m"
    $color_cyan = "`e[38;5;87m"
    $color_blue = "`e[38;5;33m"
    $color_magenta = "`e[38;5;201m"
    $color_purple = "`e[38;5;93m"
    $color_cyan_bright = "`e[38;5;51m"   ## brighter cyan (prompt user/host)
    $color_teal = "`e[38;5;66m"          ## teal/slate (prompt path)
    $color_grey = "`e[38;5;8m"           ## dim grey (prompt timestamp)
    $color_violet = "`e[38;5;99m"        ## violet (prompt brackets/delimiters)
    $color_orange = "`e[38;5;208m"       ## orange (prompt git untracked)

    $bg_color_white = "`e[48;5;15m"
    $bg_color_black = "`e[48;5;0m"
    $bg_color_red = "`e[48;5;196m"
    $bg_color_yellow = "`e[48;5;190m"
    $bg_color_green = "`e[48;5;46m"
    $bg_color_cyan = "`e[48;5;87m"
    $bg_color_blue = "`e[48;5;33m"
    $bg_color_magenta = "`e[48;5;201m"
    $bg_color_purple = "`e[48;5;93m"
#  }
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
function error($msg){     Write-Output "${bg_color_red}${color_white}[ERROR]${color_reset}:   ${color_red}$msg${color_reset}"}
function warn($msg){     Write-Output "${bg_color_yellow}${color_red}[WARNING]${color_reset}: ${color_yellow}$msg${color_reset}"}
function info($msg){     Write-Output "${bg_color_blue}${color_white}[INFO]${color_reset}:    ${color_blue}$msg${color_reset}"}
function debug($msg){   Write-Output "${bg_color_cyan}${color_yellow}[DEBUG]${color_reset}:   ${color_cyan}$msg${color_reset}"}
function success($msg){ Write-Output "${bg_color_green}${color_white}[SUCCESS]${color_reset}: ${color_cyan}$msg${color_reset}"}

###}}} END CORE HELPERS
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
