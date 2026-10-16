## ls helpers (l / ll / sl / lls)  --  colored directory listings via
## Get-ChildItemColor, with graceful fallback to Get-ChildItem when the module
## isn't available. 'lls' is a size-sorted long listing with a total.

Function l(){
  <#
  .SYNOPSIS
    List the current directory as a wide, name-only colored listing.
  .DESCRIPTION
    Uses Get-ChildItemColor's wide format (names only, colored by type) and
    falls back to a plain Get-ChildItem name list if that module isn't present.
  .EXAMPLE
    l
    Show a compact, colored name listing of the current directory.
  #>
  try { Get-ChildItemColorFormatWide | Select-Object -Property Name }
  catch { Get-ChildItem | Select-Object -Property Name }
}

Function ll(){
  <#
  .SYNOPSIS
    Long/detailed colored directory listing.
  .DESCRIPTION
    Shows a detailed, colored listing via Get-ChildItemColor, falling back to a
    full auto-sized table from Get-ChildItem when the color module is unavailable.
  .EXAMPLE
    ll
    Show a detailed listing of the current directory.
  #>
  try { Get-ChildItemColor }
  catch { Get-ChildItem | Select-Object * | Format-Table -AutoSize -Wrap }
}

## 'sl' is a built-in alias for Set-Location. Remove it (if present) so our
## own sl function can take over. Guarded so re-sourcing (reload) doesn't throw.
if (Get-Alias -Name sl -ErrorAction Ignore) { Remove-Alias -Name sl -Force }

Function sl(){
  <#
  .SYNOPSIS
    Colored directory listing (replaces the built-in 'sl' Set-Location alias).
  .DESCRIPTION
    Lists the current directory via Get-ChildItemColor, falling back to a plain
    Get-ChildItem when the color module isn't installed. The built-in 'sl' alias
    for Set-Location is removed above so this function takes over the name.
  .EXAMPLE
    sl
    Show a colored listing of the current directory.
  #>
  try { Get-ChildItemColor }
  catch { Get-ChildItem }
}

Function lls {
  <#
  .SYNOPSIS
    Long directory listing sorted by size (largest last), with a total size.
  .DESCRIPTION
    Ported from the zsh `lls` alias. Prints a playful "this could take a while"
    banner and a timestamp, then lists the directory in long format sorted by
    size — directories first, then files smallest-to-largest, so the biggest
    files sit nearest the prompt. Native PowerShell (no external tools). Prints a
    byte/MB total at the end.
  .PARAMETER Path
    Directory to list (default: the current directory).
  .EXAMPLE
    lls
    Size-sorted long listing of the current directory.
  .EXAMPLE
    lls C:\Logs
    List another directory, largest files last.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [string]$Path = '.'
  )

  # Playful banner + timestamp, matching the zsh alias.
  [Console]::Write("`e[0;1;38;5;93m🌚🌚`e[0;1;3;4;38;5;199mThis could take a while...`e[0m`e[0;1;38;5;93m🌚🌚`e[0m`t")
  Write-Host (Get-Date -Format 'yyyyMMdd_HHmmss')

  $items = Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue |
    Sort-Object -Property @{ Expression = { if ($_.PSIsContainer) { 0 } else { $_.Length } } }

  $items |
    Select-Object `
      @{ N = 'Mode';     E = { $_.Mode } },
      @{ N = 'Size';     E = { if ($_.PSIsContainer) { '' } else { '{0,12:N0}' -f $_.Length } } },
      @{ N = 'Modified'; E = { $_.LastWriteTime.ToString('yyyyMMdd-HHmmss') } },
      @{ N = 'Name';     E = { $_.Name } } |
    Format-Table -AutoSize

  $total = ($items | Where-Object { -not $_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum
  Write-Host ("Total size: {0:N0} bytes ({1:N2} MB)" -f [int64]$total, ($total / 1MB)) -ForegroundColor Cyan
}
