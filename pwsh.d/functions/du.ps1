## du  --  directory usage: per-entry recursive sizes plus a total (like 'du -sh').

Function du {
  <#
  .SYNOPSIS
    Summarize disk usage of a directory's entries (like 'du -h').
  .DESCRIPTION
    For each entry in the target directory, reports its size -- files use their
    length, directories are summed recursively -- then prints a grand total.
    Sizes are human-readable. Sorted largest-first by default. Native PowerShell,
    no external tools, so it works the same on Windows and Linux.
  .PARAMETER Path
    Directory to summarize (default: current directory).
  .PARAMETER Ascending
    Sort smallest-first instead of largest-first.
  .PARAMETER Raw
    Emit objects (with a raw Bytes property) instead of a formatted table.
  .EXAMPLE
    du
    Usage of each entry in the current directory, largest first, with a total.
  .EXAMPLE
    du C:\Users\me\Downloads
    Summarize another directory.
  .EXAMPLE
    du -Raw | Sort-Object Bytes -Descending | Select-Object -First 5
    Top 5 largest entries as objects.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [string]$Path = '.',
    [switch]$Ascending,
    [switch]$Raw
  )

  function Format-Size([double]$n) {
    if ($n -le 0) { return '0 B' }
    $u = 'B','KB','MB','GB','TB','PB'; $i = 0; $v = [double]$n
    while ($v -ge 1024 -and $i -lt $u.Count - 1) { $v /= 1024; $i++ }
    if ($i -eq 0) { '{0} {1}' -f [int64]$v, $u[$i] } else { '{0:N1} {1}' -f $v, $u[$i] }
  }

  $items = Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  $rows = foreach ($item in $items) {
    $bytes =
      if ($item.PSIsContainer) {
        (Get-ChildItem -LiteralPath $item.FullName -Recurse -File -Force -ErrorAction SilentlyContinue |
          Measure-Object -Property Length -Sum).Sum
      }
      else { $item.Length }
    if ($null -eq $bytes) { $bytes = 0 }
    [pscustomobject]@{
      Bytes = [int64]$bytes
      Size  = Format-Size $bytes
      Name  = if ($item.PSIsContainer) { "$($item.Name)/" } else { $item.Name }
    }
  }

  $rows = $rows | Sort-Object Bytes -Descending:(-not $Ascending)

  if ($Raw) { return $rows }

  $rows | Select-Object @{ N = 'Size'; E = { '{0,10}' -f $_.Size } }, Name | Format-Table -AutoSize

  $total = ($rows | Measure-Object -Property Bytes -Sum).Sum
  if ($null -eq $total) { $total = 0 }
  $c = if ($Colors) { $Colors.Cyan } else { '' }
  $r = if ($Colors) { $Colors.Reset } else { '' }
  Write-Output ("{0}total: {1}{2}" -f $c, (Format-Size $total), $r)
}
