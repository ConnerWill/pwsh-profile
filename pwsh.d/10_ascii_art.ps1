## Loaded by profile.ps1 pwsh.d loader.
## Sources ascii-art.ps1 (which defines the $Art hashtable) so the art is
## available in the session. When $ShowStartupArt is set, prints ONE random
## piece from $Art in a random color.

###{{{ ASCII ART

$__artFile = Join-Path (Split-Path -Path $PROFILE.CurrentUserAllHosts) 'ascii-art.ps1'
if (Test-Path -Path $__artFile) { . $__artFile }

if ($ShowStartupArt -and $Art -is [hashtable] -and $Art.Count -gt 0) {
  $__pick = $Art.Values | Get-Random
  # Random 256-color (skip the darkest 0-15 so it stays readable).
  $__artColor = Get-Random -Minimum 16 -Maximum 231
  Write-Output "`e[0;1;38;5;${__artColor}m$__pick`e[0m"
  Remove-Variable __pick, __artColor -ErrorAction Ignore
}

Remove-Variable __artFile -ErrorAction Ignore

###}}} END ASCII ART
