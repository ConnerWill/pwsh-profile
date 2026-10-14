## Loaded by profile.ps1 pwsh.d loader.
## Sources ascii-art.ps1 so its variables ($GRIMREAPER, $ALIENFLAMETHROWER, ...)
## are available in the session. When $ShowStartupArt is set, prints ONE random
## art piece from that file.

###{{{ ASCII ART

$__artFile = Join-Path (Split-Path -Path $PROFILE.CurrentUserAllHosts) "ascii-art.ps1"

if (Test-Path -Path $__artFile) {
  # Record existing variable names, source the art, then diff to discover which
  # variables the art file defined. This way new art added to ascii-art.ps1 is
  # automatically included in the random pool -- no need to edit this file.
  $__before = (Get-Variable).Name
  . $__artFile
  $__artNames = (Get-Variable).Name | Where-Object { $_ -notin $__before -and $_ -notlike '__*' }

  if ($ShowStartupArt) {
    # Keep only variables that actually hold (non-empty) string art.
    $__artPieces = foreach ($n in $__artNames) {
      $v = (Get-Variable -Name $n -ValueOnly -ErrorAction Ignore)
      if ($v -is [string] -and $v.Trim()) { $v }
    }

    if ($__artPieces) {
      $__pick = $__artPieces | Get-Random
      ## Random 256-color for the art (avoid the darkest 0-15 range so it stays readable).
      $__artColor = Get-Random -Minimum 16 -Maximum 231
      Write-Output "`e[0;1;38;5;${__artColor}m$__pick`e[0m"
    }
  }

  Remove-Variable __before, __artNames, __artPieces, __pick, __artColor -ErrorAction Ignore
}

Remove-Variable __artFile -ErrorAction Ignore

###}}} END ASCII ART
