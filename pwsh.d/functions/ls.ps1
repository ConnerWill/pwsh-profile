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
    true size — directory sizes are computed recursively (sum of all files
    inside), so folders and files are ranked together with the largest nearest
    the prompt. Native PowerShell (no external tools). Shows a human-readable
    size per entry and a grand total at the end.
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

  # Playful banner + timestamp, matching the zsh alias. Colors come from the
  # $Colors hashtable (single source of truth); fall back to raw escapes if it
  # isn't defined (e.g. Windows PowerShell 5).
  $c = if ($Colors -is [hashtable]) { $Colors } else {
    @{ Reset = "`e[0m"; Bold = "`e[1m"; Italic = "`e[3m"; Underline = "`e[4m"
       Purple = "`e[38;5;93m"; Magenta = "`e[38;5;201m"; Cyan = "`e[38;5;87m" }
  }
  [Console]::Write(
    "$($c.Reset)$($c.Bold)$($c.Purple)🌚🌚" +
    "$($c.Reset)$($c.Bold)$($c.Italic)$($c.Underline)$($c.Magenta)This could take a while..." +
    "$($c.Reset)$($c.Bold)$($c.Purple)🌚🌚$($c.Reset)`t"
  )
  Write-Host (Get-Date -Format 'yyyyMMdd_HHmmss')

  $items = Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue

  # Compute a true size for every entry: files use their length; directories are
  # summed recursively. Carry the raw byte size so we can sort and total on it.
  $rows = foreach ($item in $items) {
    if ($item.PSIsContainer) {
      $bytes = (Get-ChildItem -LiteralPath $item.FullName -Recurse -File -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
      if ($null -eq $bytes) { $bytes = 0 }
    }
    else {
      $bytes = $item.Length
    }
    [pscustomobject]@{
      Mode     = $item.Mode
      Bytes    = [int64]$bytes
      Modified = $item.LastWriteTime.ToString('yyyyMMdd-HHmmss')
      Name     = if ($item.PSIsContainer) { "$($item.Name)/" } else { $item.Name }
    }
  }

  # Human-readable size formatter (B/KB/MB/GB/TB).
  function Format-Size([int64]$n) {
    $u = 'B','KB','MB','GB','TB'; $i = 0; $v = [double]$n
    while ($v -ge 1024 -and $i -lt $u.Count - 1) { $v /= 1024; $i++ }
    if ($i -eq 0) { '{0} {1}' -f [int64]$v, $u[$i] } else { '{0:N1} {1}' -f $v, $u[$i] }
  }

  # Sort by true size ascending so the largest entries sit nearest the prompt
  # (matches the zsh alias's --sort=size --reverse).
  $rows |
    Sort-Object Bytes |
    Select-Object `
      Mode,
      @{ N = 'Size'; E = { '{0,10}' -f (Format-Size $_.Bytes) } },
      Modified,
      Name |
    Format-Table -AutoSize

  $total = ($rows | Measure-Object -Property Bytes -Sum).Sum
  if ($null -eq $total) { $total = 0 }
  Write-Host ("$($c.Cyan)Total size: {0} ({1:N0} bytes)$($c.Reset)" -f (Format-Size $total), [int64]$total)
}
