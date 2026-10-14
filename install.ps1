#Requires -Version 7.0
<#
.SYNOPSIS
  Bootstrap / setup for the pwsh-profile.

.DESCRIPTION
  Clones (or updates) this profile into your PowerShell profile directory and
  installs the modules it expects. Safe to run two ways:

    * Standalone bootstrap (repo not cloned yet):
        Invoke-RestMethod https://raw.githubusercontent.com/ConnerWill/pwsh-profile/main/install.ps1 | Invoke-Expression
      or download it and run:
        pwsh -NoProfile -File .\install.ps1

    * From inside an existing clone (just updates + installs modules):
        pwsh -NoProfile -File "$HOME\Documents\PowerShell\install.ps1"

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
Write-Host "`e[0;1;38;5;${__bannerColor}m$__banner`e[0m"
Write-Host "`e[0;1;38;5;51m  pwsh-profile installer`e[0m`n"

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

Write-Host ""
Write-Host "Setup complete. Open a new PowerShell 7 session (or run 'reload')." -ForegroundColor Green
