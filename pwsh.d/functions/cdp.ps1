## cd / navigation helpers.

## $OLDPWD support (like bash/zsh): track the previous directory so you can
## `cd $OLDPWD` or `cd -` to jump back. The built-in `cd` is an alias for
## Set-Location; replace it (guarded so reload doesn't throw) with a wrapper
## that records the old location on every change.
if (Get-Alias -Name cd -ErrorAction Ignore) { Remove-Alias -Name cd -Force }

Function cd {
  <#
  .SYNOPSIS
    Change directory with $OLDPWD tracking and 'cd -' support (bash/zsh style).
  .DESCRIPTION
    Replaces the built-in 'cd' alias for Set-Location with a wrapper that records
    the previous directory in $global:OLDPWD on every successful move. Supports:
      * 'cd -'          jump back to the previous directory
      * 'cd' (no args)  go to $HOME
      * 'cd <path>'     change to a path
  .PARAMETER Path
    Target directory, or '-' to return to the previous directory.
  .EXAMPLE
    cd C:\Projects
    Change to a directory (and remember where you were).
  .EXAMPLE
    cd -
    Jump back to the previous directory.
  .EXAMPLE
    cd
    Go to your home directory.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [string]$Path
  )

  $previous = $PWD.Path

  # `cd -` jumps to the previous directory (bash-style).
  if ($Path -eq '-') {
    if ($global:OLDPWD) { $Path = $global:OLDPWD }
    else { Write-Warning 'OLDPWD not set yet.'; return }
  }
  # `cd` with no argument goes HOME (bash-style).
  elseif ([string]::IsNullOrEmpty($Path)) {
    $Path = $HOME
  }

  Set-Location -Path $Path -ErrorAction Stop
  # Only record once the move succeeded, and only if we actually moved.
  if ($previous -ne $PWD.Path) { $global:OLDPWD = $previous }
}

## cd to the PowerShell profile directory.
Function cdp(){
  <#
  .SYNOPSIS
    Change to the PowerShell profile directory.
  .DESCRIPTION
    Jumps to the directory containing your profile (where profile.ps1 and
    pwsh.d live), so you can quickly edit or inspect your configuration.
  .EXAMPLE
    cdp
    Change into the profile directory.
  #>
  Set-Location (Split-Path -Path $PROFILE -Parent)
}

## Directory-up shortcuts (like zsh): typing dots alone walks up parents.
##   ..     -> up 1      ...   -> up 2
##   ....   -> up 3      ..... -> up 4
## (Plain `.` is left alone -- current dir / dot-source operator.)

Function ..    {
  <#
  .SYNOPSIS
    Go up one directory.
  .EXAMPLE
    ..
    Move to the parent directory.
  #>
  Set-Location ..
}
Function ...   {
  <#
  .SYNOPSIS
    Go up two directories.
  .EXAMPLE
    ...
    Move up two parent directories.
  #>
  Set-Location (Join-Path .. ..)
}
Function ....  {
  <#
  .SYNOPSIS
    Go up three directories.
  .EXAMPLE
    ....
    Move up three parent directories.
  #>
  Set-Location (Join-Path .. (Join-Path .. ..))
}
Function ..... {
  <#
  .SYNOPSIS
    Go up four directories.
  .EXAMPLE
    .....
    Move up four parent directories.
  #>
  Set-Location (Join-Path .. (Join-Path .. (Join-Path .. ..)))
}

## realpath (alias rp): resolve a path to its absolute, canonical form
## (like 'realpath' in linux). Resolves .., ~, and relative paths. Works for
## paths that don't exist yet, too. Defaults to the current directory.
## ('rp' is a built-in alias for Remove-ItemProperty; drop it so ours wins.
## Guarded so re-sourcing doesn't throw.)
if (Get-Alias -Name rp -ErrorAction Ignore) { Remove-Alias -Name rp -Force }

Function realpath {
  <#
  .SYNOPSIS
    Resolve a path to its absolute, canonical form (like Linux 'realpath').
  .DESCRIPTION
    Expands '..', '~', and relative segments into a full absolute path. Resolves
    existing items through the provider; for paths that don't exist yet it falls
    back to normalizing against the current directory. Accepts multiple paths and
    pipeline input, and defaults to the current directory.
  .PARAMETER Path
    One or more paths to resolve (default: '.'). Accepts pipeline input.
  .EXAMPLE
    realpath ..\foo
    Resolve a relative path to its absolute form.
  .EXAMPLE
    rp ~/Documents
    Expand '~' to the full home path (via the 'rp' alias).
  .EXAMPLE
    '.', '..', 'nope.txt' | realpath
    Resolve several paths from the pipeline (including a non-existent one).
  #>
  [CmdletBinding()]
  [Alias('rp')]
  param(
    [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
    [string[]]$Path = @('.')
  )
  process {
    foreach ($p in $Path) {
      # Try a real resolve first (follows the provider / existing items)...
      $resolved = Resolve-Path -LiteralPath $p -ErrorAction Ignore
      if ($resolved) { $resolved.Path }
      else {
        # ...fall back to GetFullPath for not-yet-existing paths, resolved
        # against the current directory.
        [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $p))
      }
    }
  }
}
