## Motd-AsciiArt  --  print a random ASCII art banner from the $Art hashtable.

Function Motd-AsciiArt(){
  <#
  .SYNOPSIS
    Print a random ASCII-art banner from the $Art hashtable.
  .DESCRIPTION
    Picks a random entry from the $Art hashtable (loading ascii-art.ps1 first if
    $Art isn't defined yet) and prints it in color. Used as a message-of-the-day
    style banner; the startup banner uses the same source.
  .EXAMPLE
    Motd-AsciiArt
    Print a random piece of ASCII art.
  #>
  if (-not ($Art -is [hashtable])) {
    $artFile = Join-Path (Split-Path -Path $PROFILE.CurrentUserAllHosts) 'ascii-art.ps1'
    if (Test-Path -Path $artFile) { . $artFile }
  }
  if ($Art -is [hashtable] -and $Art.Count -gt 0) {
    $pick = $Art.Values | Get-Random
    Write-Output "`e[0;38;5;196m$pick`e[0m"
  }
}
