## Motd-AsciiArt  --  print a random ASCII art banner from the $Art hashtable.

Function Motd-AsciiArt(){
  # Ensure the art is loaded (defines $Art).
  if (-not ($Art -is [hashtable])) {
    $artFile = Join-Path (Split-Path -Path $PROFILE.CurrentUserAllHosts) 'ascii-art.ps1'
    if (Test-Path -Path $artFile) { . $artFile }
  }
  if ($Art -is [hashtable] -and $Art.Count -gt 0) {
    $pick = $Art.Values | Get-Random
    Write-Output "`e[0;38;5;196m$pick`e[0m"
  }
}
