## df  --  disk free: show filesystem usage like Linux 'df -h'.

Function df {
  <#
  .SYNOPSIS
    Show filesystem disk space usage (like 'df -h').
  .DESCRIPTION
    Lists mounted drives/volumes with size, used, free, and percent-used, in
    human-readable units. Prefers Get-Volume (rich info incl. filesystem and
    label); falls back to Get-PSDrive on the FileSystem provider when Get-Volume
    isn't available. Use -Raw to emit the underlying objects instead of a table.
  .PARAMETER Raw
    Return objects instead of a formatted table (for sorting/filtering).
  .EXAMPLE
    df
    Show all filesystems with human-readable sizes.
  .EXAMPLE
    df | Where-Object { $_.'Use%' -gt 90 }
    (With -Raw) find nearly-full volumes.
  #>
  [CmdletBinding()]
  param([switch]$Raw)

  function Format-Size([double]$n) {
    if ($n -le 0) { return '0 B' }
    $u = 'B','KB','MB','GB','TB','PB'; $i = 0; $v = [double]$n
    while ($v -ge 1024 -and $i -lt $u.Count - 1) { $v /= 1024; $i++ }
    if ($i -eq 0) { '{0} {1}' -f [int64]$v, $u[$i] } else { '{0:N1} {1}' -f $v, $u[$i] }
  }

  $rows =
    if (Get-Command Get-Volume -ErrorAction Ignore) {
      Get-Volume -ErrorAction SilentlyContinue |
        Where-Object { $_.Size -gt 0 } |
        ForEach-Object {
          $used = $_.Size - $_.SizeRemaining
          [pscustomobject]@{
            Drive      = if ($_.DriveLetter) { "$($_.DriveLetter):" } else { $_.Path }
            Label      = $_.FileSystemLabel
            FS         = $_.FileSystem
            Size       = Format-Size $_.Size
            Used       = Format-Size $used
            Free       = Format-Size $_.SizeRemaining
            'Use%'     = if ($_.Size) { [int](($used / $_.Size) * 100) } else { 0 }
          }
        }
    }
    else {
      Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue |
        Where-Object { ($_.Used + $_.Free) -gt 0 } |
        ForEach-Object {
          $size = $_.Used + $_.Free
          [pscustomobject]@{
            Drive  = $_.Name
            Root   = $_.Root
            Size   = Format-Size $size
            Used   = Format-Size $_.Used
            Free   = Format-Size $_.Free
            'Use%' = if ($size) { [int](($_.Used / $size) * 100) } else { 0 }
          }
        }
    }

  if ($Raw) { $rows } else { $rows | Format-Table -AutoSize }
}
