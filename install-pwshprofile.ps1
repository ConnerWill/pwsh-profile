#Requires -Version 7.0
<#
.SYNOPSIS
  Bootstrap / setup for the pwsh-profile.

.DESCRIPTION
  Clones (or updates) this profile into your PowerShell profile directory and
  installs the modules it expects. Safe to run two ways:

    * Standalone bootstrap (repo not cloned yet):
        Invoke-RestMethod https://raw.githubusercontent.com/ConnerWill/pwsh-profile/main/install-pwshprofile.ps1 | Invoke-Expression
      or download it and run:
        pwsh -NoProfile -File .\install-pwshprofile.ps1

    * From inside an existing clone (just updates + installs modules):
        pwsh -NoProfile -File "$HOME\Documents\PowerShell\install-pwshprofile.ps1"

  It is intentionally NOT loaded on shell startup.

.PARAMETER Force
  Reinstall modules even if already present.

.PARAMETER SkipClone
  Only install modules; do not clone/update the repo.

.PARAMETER RepoUrl
  Override the git URL to clone from.
#>
[CmdletBinding()]
param(
  [switch]$Force,
  [switch]$SkipClone,
  [string]$RepoUrl = 'https://github.com/ConnerWill/pwsh-profile.git'
)

$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------------------
# Fail fast: this profile targets PowerShell 7+. #Requires above handles the
# normal file-run case, but it is NOT enforced when the script is piped to
# Invoke-Expression (the bootstrap one-liner), so guard explicitly too.
# -----------------------------------------------------------------------------
if ($PSVersionTable.PSVersion.Major -lt 7) {
  Write-Host "`e[1;41;97m[ERROR]`e[0m This profile requires PowerShell 7+. You are on $($PSVersionTable.PSVersion)." -ForegroundColor Red
  Write-Host "Install PowerShell 7 (https://aka.ms/powershell) and re-run from 'pwsh'." -ForegroundColor Yellow
  exit 1
}

# -----------------------------------------------------------------------------
# Embedded rainbow loading bar (self-contained -- the installer may run via
# 'irm | iex' before the profile's Show-RainbowLoadingBar function exists).
# -----------------------------------------------------------------------------
function Show-RainbowBar([double]$Duration = 0.5) {
  $cols = try { [Console]::WindowWidth } catch { 0 }
  if ($cols -le 0) { $cols = 80 }
  $delayMs = [int](($Duration * 1000) / $cols)
  $e = "`e"
  [Console]::Write("$e[?25l")
  try {
    for ($i = 0; $i -lt $cols; $i++) {
      $n = if ($cols -gt 1) { [int]($i * 255 / ($cols - 1)) } else { 0 }
      $h = [int][math]::Floor($n / 43); $f = $n - 43 * $h
      $t = [int]($f * 255 / 43); $q = 255 - $t
      $rgb = switch ($h) { 0 {255,$t,0} 1 {$q,255,0} 2 {0,255,$t} 3 {0,$q,255} 4 {$t,0,255} default {255,0,$q} }
      [Console]::Write("$e[48;2;$($rgb[0]);$($rgb[1]);$($rgb[2])m ")
      if ($delayMs -gt 0) { Start-Sleep -Milliseconds $delayMs }
    }
  }
  finally { [Console]::Write("$e[0m$e[?25h`n") }
}

# Print a multi-line block horizontally centered as a WHOLE (same left pad on
# every line, based on the widest line) so ASCII art keeps its internal shape.
# $Color is an optional ANSI escape prefix applied to each line.
function Write-CenteredBlock([string]$Text, [string]$Color = '') {
  $cols = try { [Console]::WindowWidth } catch { 0 }
  if ($cols -le 0) { $cols = 80 }
  $reset = if ($Color) { "`e[0m" } else { '' }
  $lines = $Text -split "`r?`n"
  $widest = ($lines | Measure-Object -Property Length -Maximum).Maximum
  $pad = [int](($cols - $widest) / 2)
  if ($pad -lt 0) { $pad = 0 }
  $prefix = ' ' * $pad
  foreach ($line in $lines) {
    Write-Host ($prefix + $Color + $line + $reset)
  }
}

Show-RainbowBar 0.5

# -----------------------------------------------------------------------------
# Banner
# -----------------------------------------------------------------------------
$__banner = @'

                     .-+=======---::..
                   :=+##@@@@@@@@@@@@@%@@@#.
                .=:*=@#@@@@@@%@@@@@@@@@@@@%+.      ..
  ...::..    .:+.*=%%%@@@@@@*%@@@@@@@@@@@@@%#-.    ..
 .%@@@%%%%*--=.=*+@#@@@@@@@@=#@@@@@@@@@@@@@@@##-.:..:
 *@@@@@@@@@@@@@=%@##%%#####*+%%#%%%%%%%%%%%@@@@*%#@%%#*+=:..
=%#....................:::::::--:-+#@@@@@@@@@@@@@#*%@@@@@%%#+=+*+:.
#@@*=-:-::.-@@#**%@@-.       +%%.    .... . ...............:-=+#%@@%+:.
 #%@@@@@@@%*@@@@@@@@=.#@@@@%@@@@@@@%%%%%###*=:-:......  .#%%##%=.    .:=.
#%###**++++@@@@+::-#@@@:---==++***###%%%%@@@@@@#%*@@@@@@:*@@@@@@#+%%+==#@.
=@@@@@@@@@@@@*.     :@@@@@@@@@@@%%%%%##****+++=---:::..:@@@%-:=@@@-::::..
=#*++@@@@@@@. :@@%. =@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=    .*@@@@@@@@@-
  .:=#%@@@@%. =@@@: =@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#..@@=.:@@@@@@@@:.
          .@=  .:. .%%++:..:::::::::--------===#%%%%%%%@#..%@-.:@%%%%%=
           .%#:. .=@%.                                 -@+    .**.
            .:#@@@#-.                                   -@@+=*@+.
                                                         ..--:.
'@
$__bannerColor = Get-Random -Minimum 16 -Maximum 231
Write-CenteredBlock $__banner "`e[0;1;38;5;${__bannerColor}m"
Write-CenteredBlock 'pwsh-profile installer' "`e[0;1;38;5;51m"
Write-Host ''

# Target = the CurrentUserAllHosts profile directory (handles OneDrive redirect).
$ProfileDir = Split-Path -Path $PROFILE.CurrentUserAllHosts

function Test-IsThisRepo {
  param([string]$Path)
  (Test-Path (Join-Path $Path 'profile.ps1')) -and
  (Test-Path (Join-Path $Path 'pwsh.d'))
}

# --------------------------------------------------------------------------
# 1. Clone or update the repo into the profile directory.
# --------------------------------------------------------------------------
if (-not $SkipClone) {
  if (-not (Get-Command git -ErrorAction Ignore)) {
    Write-Warning "git not found on PATH; skipping clone/update. Install git, or re-run with -SkipClone after cloning manually."
  }
  elseif (Test-IsThisRepo -Path $ProfileDir) {
    # Already installed here -> update if it's a git repo.
    if (Test-Path (Join-Path $ProfileDir '.git')) {
      Write-Host "Updating existing profile at: $ProfileDir" -ForegroundColor Cyan
      git -C $ProfileDir pull --ff-only
    }
    else {
      Write-Host "Profile already present (not a git clone) at: $ProfileDir -- leaving as is." -ForegroundColor DarkGray
    }
  }
  else {
    # Back up any existing (non-repo) profile dir, then clone.
    if (Test-Path $ProfileDir) {
      $backup = "$ProfileDir.bak-$(Get-Date -Format yyyyMMddHHmmss)"
      Write-Host "Backing up existing profile dir -> $backup" -ForegroundColor Yellow
      Rename-Item -Path $ProfileDir -NewName $backup
    }
    $parent = Split-Path -Path $ProfileDir -Parent
    if (-not (Test-Path $parent)) { New-Item -Path $parent -ItemType Directory -Force | Out-Null }
    Write-Host "Cloning $RepoUrl -> $ProfileDir" -ForegroundColor Cyan
    git clone $RepoUrl $ProfileDir
  }
}

# --------------------------------------------------------------------------
# 2. Install the modules the profile expects (idempotent).
# --------------------------------------------------------------------------
$Modules = @(
  'Get-ChildItemColor'   # used by l / ll / sl
  'PSReadLine'
  'posh-git'
  'Plaster'
  'PSFunctionTools'
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

# -----------------------------------------------------------------------------
# Done -- rainbow transition, then goodbye banner, then the "try it out" guide.
# -----------------------------------------------------------------------------
Show-RainbowBar 0.5

# Centered goodbye banner (styled after the zsh installer's show_ascii_goodbye).
$__cols = try { [Console]::WindowWidth } catch { 0 }
if ($__cols -le 0) { $__cols = 80 }
$__magenta = "`e[0;1;38;5;201m"
$__green   = "`e[0;1;38;5;46m"

Write-Host ("$__magenta" + ('▀' * $__cols) + "`e[0m")

$__goodbye = @'
 +------+.      +------+       +------+       +------+      .+------+
 |`.    | `.    |\     |\      |      |      /|     /|    .' |    .'|
 |  `+--+---+   | +----+-+     +------+     +-+----+ |   +---+--+'  |
 |   |  |   |   | |    | |     |      |     | |    | |   |   |  |   |
 +---+--+.  |   +-+----+ |     +------+     | +----+-+   |  .+--+---+
  `. |    `.|    \|     \|     |      |     |/     |/    |.'    | .'
    `+------+     +------+     +------+     +------+     +------+'
'@
Write-CenteredBlock $__goodbye $__green
Write-CenteredBlock 'GOODBYE :)' "`e[0;1;3;38;5;201m"

Write-Host ("$__magenta" + ('▀' * $__cols) + "`e[0m")

Remove-Variable __cols, __magenta, __green, __goodbye -ErrorAction Ignore

# "Try it out" guide -- shown last.
$e = "`e"
$c = @{
  reset = "$e[0m"; bold = "$e[1m"; ul = "$e[4m"; it = "$e[3m"
  cyan = "$e[38;5;51m"; green = "$e[38;5;46m"; grey = "$e[38;5;8m"
  orange = "$e[38;5;208m"; white = "$e[38;5;15m"
}

$guide = @"

$($c.bold)$($c.ul)$($c.cyan)Setup complete — a few things to try:$($c.reset)

$($c.bold)$($c.green)  1. Reload / start a fresh session (loads everything):$($c.reset)
$($c.cyan)       ez               $($c.grey)# or 'reload', or open a new pwsh$($c.reset)

$($c.bold)$($c.green)  2. The prompt shows git status inside a repo:$($c.reset)
$($c.cyan)       cd <a git repo>  $($c.grey)# branch + counts: green=clean, red=untracked...$($c.reset)

$($c.bold)$($c.green)  3. Navigation:$($c.reset)
$($c.cyan)       ..   ...   ....  $($c.grey)# go up 1 / 2 / 3 directories$($c.reset)
$($c.cyan)       cd -             $($c.grey)# jump back to the previous directory$($c.reset)
$($c.cyan)       cdp              $($c.grey)# cd to the profile directory$($c.reset)

$($c.bold)$($c.green)  4. Try some functions:$($c.reset)
$($c.cyan)       Get-ANSIColors   $($c.grey)# the 256-color block palette$($c.reset)
$($c.cyan)       Show-Colors      $($c.grey)# color/ANSI reference (-Style List/Table/Ansi/All)$($c.reset)
$($c.cyan)       touch f.txt      $($c.grey)# create an empty file$($c.reset)
$($c.cyan)       which ez         $($c.grey)# resolve a command/alias/function$($c.reset)
$($c.cyan)       Get-PwSHKeybindings  $($c.grey)# list PSReadLine key handlers$($c.reset)

$($c.bold)$($c.it)$($c.orange)  Tip: run '$($c.cyan)e$($c.orange)' to open your editor (`$EDITOR).$($c.reset)
$($c.bold)$($c.it)$($c.orange)  Tip: personal overrides go in '$($c.cyan)powershell-config.ps1$($c.orange)' (gitignored).$($c.reset)
$($c.bold)$($c.it)$($c.orange)  Docs: $($c.green)https://github.com/ConnerWill/pwsh-profile$($c.reset)

"@

Write-Host $guide
