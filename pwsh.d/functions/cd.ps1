## cd / navigation helpers.

## $OLDPWD support (like bash/zsh): track the previous directory so you can
## `cd $OLDPWD` or `cd -` to jump back. The built-in `cd` is an alias for
## Set-Location; replace it (guarded so reload doesn't throw) with a wrapper
## that records the old location on every change.
if (Get-Alias -Name cd -ErrorAction Ignore) { Remove-Alias -Name cd -Force }

Function cd {
  <#
  .SYNOPSIS
    Change directory with $OLDPWD tracking, 'cd -' support, and smart
    file-to-parent correction (bash/zsh style).
  .DESCRIPTION
    Replaces the built-in 'cd' alias for Set-Location with a wrapper that records
    the previous directory in $global:OLDPWD on every successful move. Supports:
      * 'cd -'          jump back to the previous directory
      * 'cd' (no args)  go to $HOME
      * 'cd <dir>'      change to a directory
      * 'cd <file>'     "smart cd": switch to the file's parent directory
                        (e.g. 'cd /etc/fstab' moves to /etc)
    When the target doesn't exist, prints a clear, colored error. Colors come
    from the profile's $Colors table (single source of truth in profile.ps1),
    which is only defined on PS versions that support ANSI -- so output is plain
    when $Colors isn't available.
  .PARAMETER Path
    Target directory or file, or '-' to return to the previous directory.
  .EXAMPLE
    cd C:\Projects
    Change to a directory (and remember where you were).
  .EXAMPLE
    cd /etc/fstab
    Target is a file, so move to its parent directory (/etc) instead.
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

  # Pull message styling from $Colors when available; otherwise go plain.
  # Closest semantic matches to the zsh original (correcting=red-ish,
  # corrected=green, error banner=white-on-red, error path=blue).
  if ($Colors) {
    $cCorrecting = "$($Colors.Bold)$($Colors.Orange)"
    $cCorrected  = "$($Colors.Bold)$($Colors.Green)"
    $cErrorMsg   = $Colors.Yellow
    $cErrorTag   = "$($Colors.Bold)$($Colors.BgRed)$($Colors.White)"
    $cErrorPath  = "$($Colors.Italic)$($Colors.Underline)$($Colors.Blue)"
    $cReset      = $Colors.Reset
  }
  else {
    $cCorrecting = $cCorrected = $cErrorMsg = $cErrorTag = $cErrorPath = $cReset = ''
  }

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
  # Smart cd: if the target is a file, switch to its parent directory instead
  # (e.g. `cd /etc/fstab` -> /etc). Mirrors the zsh `${1:h}` helper.
  elseif (Test-Path -LiteralPath $Path -PathType Leaf) {
    $parent = Split-Path -Path $Path -Parent
    # Empty parent means a bare filename in the current dir -> stay put.
    if ([string]::IsNullOrEmpty($parent)) { $parent = '.' }
    if (-not (Test-Path -LiteralPath $parent)) { return }
    Write-Output "Correcting ${cCorrecting}${Path}${cReset} to ${cCorrected}${parent}${cReset}"
    $Path = $parent
  }
  # Anything else that isn't an existing directory -> colored error.
  elseif (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    Write-Output "${cErrorTag} Error ${cReset} ${cErrorMsg}Directory does not exist${cReset} ${cErrorPath}${Path}${cReset}"
    return
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

