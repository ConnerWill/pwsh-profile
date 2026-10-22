## mkcd  --  make a directory (and any parents) then cd into it.

Function mkcd {
  <#
  .SYNOPSIS
    Create a directory (and any missing parents) and change into it.
  .DESCRIPTION
    The common shell helper: 'mkcd foo/bar/baz' creates the full path if needed
    and immediately sets the location there. If the directory already exists it
    just cds into it. Uses the profile's 'cd' wrapper when available (so $OLDPWD
    tracking still works), otherwise Set-Location.
  .PARAMETER Path
    The directory to create and enter.
  .EXAMPLE
    mkcd project
    Create ./project and cd into it.
  .EXAMPLE
    mkcd src/app/components
    Create the whole nested path, then cd into the deepest folder.
  .EXAMPLE
    mkcd existing-dir
    If it already exists, just cd into it (no error).
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    try { New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null }
    catch { Write-Error "mkcd: failed to create '$Path': $($_.Exception.Message)"; return }
  }
  Set-Location -LiteralPath $Path
}
