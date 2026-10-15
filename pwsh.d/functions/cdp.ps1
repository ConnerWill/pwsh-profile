## cd / navigation helpers.

## $OLDPWD support (like bash/zsh): track the previous directory so you can
## `cd $OLDPWD` or `cd -` to jump back. The built-in `cd` is an alias for
## Set-Location; replace it (guarded so reload doesn't throw) with a wrapper
## that records the old location on every change.
if (Get-Alias -Name cd -ErrorAction Ignore) { Remove-Alias -Name cd -Force }

Function cd {
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
  Set-Location (Split-Path -Path $PROFILE -Parent)
}

## Directory-up shortcuts (like zsh): typing dots alone walks up parents.
##   ..     -> up 1      ...   -> up 2
##   ....   -> up 3      ..... -> up 4
## (Plain `.` is left alone -- current dir / dot-source operator.)
Function ..    { Set-Location .. }
Function ...   { Set-Location (Join-Path .. ..) }
Function ....  { Set-Location (Join-Path .. (Join-Path .. ..)) }
Function ..... { Set-Location (Join-Path .. (Join-Path .. (Join-Path .. ..))) }
