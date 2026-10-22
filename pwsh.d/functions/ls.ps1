## ls helpers (ls / l / ll / sl / lls)  --  colored directory listings via
## Get-ChildItemColor, with graceful fallback to Get-ChildItem when the module
## isn't available. 'ls' mimics Linux ls (color + bundled short flags like
## -a / -l / -al). 'lls' is a size-sorted long listing with a total.

## 'ls' is a built-in alias for Get-ChildItem. Remove it (if present) so our
## own ls function takes over. Guarded so re-sourcing (reload) doesn't throw.
if (Get-Alias -Name ls -ErrorAction Ignore) { Remove-Alias -Name ls -Force }

## Shared: resolve the 'lsd' tool (https://github.com/lsd-rs/lsd) if installed.
## When present, ls/l/ll/sl/lst/lls delegate to lsd (color + icons, like the
## zsh vendor aliases); otherwise they fall back to the Get-ChildItemColor
## implementations below.
Function Get-LsdCommand {
  Get-Command lsd -CommandType Application -ErrorAction Ignore | Select-Object -First 1
}

Function ls {
  <#
  .SYNOPSIS
    Linux-like 'ls': colored, formatted directory listing with bundled flags.
  .DESCRIPTION
    Lists directories the way 'ls' does on Linux. Uses 'lsd' (with color + icons)
    when it's installed; otherwise falls back to Get-ChildItemColor, and finally
    to plain Get-ChildItem. Supports the common short flags as real switches, so
    pass them separately ('ls -a -l'); bundled Unix forms ('ls -al', 'ls -ltr')
    are also parsed on a best-effort basis. Flags:
      -a        show hidden/system entries
      -l        long/detailed format instead of the wide view
      -Recurse  recurse into subdirectories (bundled '-R' also works)
      -t        sort by last-write time (newest first)
      -S        sort by size (largest first)
      -r        reverse the sort order
      -d        list directories only
      -f        list files only
    Note: PowerShell parameter names are case-insensitive, so recursion is
    '-Recurse' (not '-R') to avoid clashing with '-r' (reverse); bundled '-R'
    inside a token like '-Rl' is still honored.
  .PARAMETER a
    Show hidden/system entries (like 'ls -a'; adds -Force).
  .PARAMETER l
    Long/detailed colored listing (like 'ls -l').
  .PARAMETER Recurse
    Recurse into subdirectories (like 'ls -R').
  .PARAMETER t
    Sort by last-write time, newest first (like 'ls -t').
  .PARAMETER S
    Sort by size, largest first (like 'ls -S').
  .PARAMETER r
    Reverse the sort order (like 'ls -r').
  .PARAMETER d
    List directories only.
  .PARAMETER f
    List files only.
  .PARAMETER Rest
    The path to list, plus any bundled flag token (e.g. '-al'). Separate flags
    ('-a -l') are the reliable form.
  .EXAMPLE
    ls
    Wide, colored listing of the current directory.
  .EXAMPLE
    ls -a
    Include hidden/system entries.
  .EXAMPLE
    ls -a -l
    Long listing including hidden entries.
  .EXAMPLE
    ls -ltr /var/log
    Long listing of /var/log, sorted by time, reversed (oldest last).
  .EXAMPLE
    ls -S -l
    Long listing sorted by size, largest first.
  #>
  [CmdletBinding()]
  param(
    # Real switches so 'ls -a -l' binds cleanly (PowerShell can't split a
    # bundled '-al' into switches, so bundles are also parsed from -Rest below).
    [switch]$a,   # all (show hidden/system)
    [switch]$l,   # long format
    [switch]$t,   # sort by time
    [switch]$S,   # sort by size
    [switch]$r,   # reverse sort
    [switch]$d,   # directories only
    [switch]$f,   # files only
    [switch]$Recurse,   # recurse (PowerShell params are case-insensitive, so a
                        # separate '-R' switch would clash with '-r'; use
                        # -Recurse, or the bundled '-R' letter which is parsed below)

    # Anything else: the path, plus any bundled flag token like '-al' (best
    # effort -- separate flags like '-a -l' are the reliable form).
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Rest
  )

  # --- Fold any bundled flag tokens (-al, -ltr) into the switch values. ------
  $paths = @()
  foreach ($arg in $Rest) {
    if ($arg -match '^-{1,2}[A-Za-z]+$') {
      foreach ($ch in ($arg -replace '^-+', '').ToCharArray()) {
        switch -c ($ch) {
          'a' { $a = $true } 'l' { $l = $true } 'R' { $Recurse = $true }
          't' { $t = $true } 'S' { $S = $true } 'r' { $r = $true }
          'd' { $d = $true } 'f' { $f = $true }
        }
      }
    }
    elseif ($arg -ne '--') { $paths += $arg }
  }
  $Path = if ($paths.Count) { $paths[0] } else { '.' }

  $all      = [bool]$a
  $long     = [bool]$l
  $recurse  = [bool]$Recurse
  $byTime   = [bool]$t
  $bySize   = [bool]$S
  $reverse  = [bool]$r
  $dirOnly  = [bool]$d
  $fileOnly = [bool]$f

  # --- lsd first: if lsd is installed, delegate with mapped flags. -----------
  $lsd = Get-LsdCommand
  if ($lsd) {
    $o = @('--color', 'always', '--icon', 'always')
    if ($all)      { $o += '--almost-all' }
    if ($long)     { $o += '--long' }
    if ($recurse)  { $o += '--recursive' }
    if ($byTime)   { $o += '--timesort' }
    if ($bySize)   { $o += '--sizesort' }
    if ($reverse)  { $o += '--reverse' }
    if ($dirOnly)  { $o += '--directory-only' }
    & $lsd.Source @o $Path
    return
  }

  # --- Build the argument splat for Get-ChildItemColor. ----------------------
  $gci = @{ Path = $Path }
  if ($all)      { $gci.Force     = $true }
  if ($recurse)  { $gci.Recurse   = $true }
  if ($dirOnly)  { $gci.Directory = $true }
  if ($fileOnly) { $gci.File      = $true }

  $hasColor = [bool](Get-Command Get-ChildItemColor -ErrorAction Ignore)

  # When a sort is requested we must gather items first, sort, then render,
  # because the color formatters output as they go.
  $needSort = $byTime -or $bySize -or $reverse

  if ($needSort) {
    $items = Get-ChildItem @gci -ErrorAction SilentlyContinue
    $items =
      if     ($byTime) { $items | Sort-Object LastWriteTime -Descending:(-not $reverse) }
      elseif ($bySize) { $items | Sort-Object Length -Descending:(-not $reverse) }
      else             { $items | Sort-Object Name -Descending:$reverse }

    if ($long) { $items | Format-Table -AutoSize }
    else       { $items | Select-Object -ExpandProperty Name }
    return
  }

  # No custom sort: hand off to the color formatters directly.
  if ($hasColor) {
    if ($long) { Get-ChildItemColor @gci }
    else       { Get-ChildItemColorFormatWide -Path $Path -Force:$all }
  }
  else {
    # Fallback: plain Get-ChildItem.
    if ($long) { Get-ChildItem @gci | Format-Table -AutoSize }
    else       { Get-ChildItem @gci | Select-Object -ExpandProperty Name }
  }
}

Function lst {
  <#
  .SYNOPSIS
    Long directory listing sorted by modification time (newest first).
  .DESCRIPTION
    Convenience wrapper over 'ls' that always sorts by last-write time in a long
    (detailed) listing -- equivalent to 'ls -l -t'. Add -r to reverse (oldest
    first), and -a to include hidden entries. Passes the path through to 'ls'.
  .PARAMETER Path
    Directory to list (default: current directory).
  .PARAMETER r
    Reverse the order (oldest first).
  .PARAMETER a
    Include hidden/system entries.
  .EXAMPLE
    lst
    Long listing of the current directory, newest first.
  .EXAMPLE
    lst -r
    Oldest first.
  .EXAMPLE
    lst -a /var/log
    Include hidden entries, listing /var/log newest first.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [string]$Path = '.',
    [switch]$r,
    [switch]$a
  )
  ls -l -t -r:$r -a:$a $Path
}

Function l(){
  <#
  .SYNOPSIS
    List the current directory one entry per line (like 'ls -1'), colored by type.
  .DESCRIPTION
    Single-column listing: one name per line, colored by type using the profile's
    $Colors table (directories blue, executables green, symlinks cyan, otherwise
    default). Directories get a trailing '/'. Falls back to plain names when
    $Colors isn't defined.
  .EXAMPLE
    l
    One-per-line colored listing of the current directory.
  #>
  [CmdletBinding()]
  param([Parameter(Position = 0)][string]$Path = '.')

  # lsd first: 'lsd --oneline --no-symlink --almost-all' (matches zsh alias).
  $lsd = Get-LsdCommand
  if ($lsd) {
    & $lsd.Source --color always --icon always --oneline --no-symlink --almost-all $Path
    return
  }

  $dirCol = if ($Colors) { $Colors.Blue }  else { '' }
  $exeCol = if ($Colors) { $Colors.Green } else { '' }
  $lnkCol = if ($Colors) { $Colors.Cyan }  else { '' }
  $reset  = if ($Colors) { $Colors.Reset } else { '' }

  Get-ChildItem -LiteralPath $Path -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.PSIsContainer) {
      "$dirCol$($_.Name)/$reset"
    }
    elseif ($_.LinkType) {
      "$lnkCol$($_.Name)$reset"
    }
    elseif ($_.Extension -in '.exe', '.cmd', '.bat', '.ps1', '.sh', '.com') {
      "$exeCol$($_.Name)$reset"
    }
    else {
      $_.Name
    }
  }
}

Function ll(){
  <#
  .SYNOPSIS
    Long/detailed colored directory listing.
  .DESCRIPTION
    Uses 'lsd' when installed (long, octal permissions, dated); otherwise a
    detailed colored listing via Get-ChildItemColor, falling back to a full
    auto-sized Get-ChildItem table when neither is available.
  .PARAMETER Path
    Directory to list (default: current directory).
  .EXAMPLE
    ll
    Show a detailed listing of the current directory.
  #>
  [CmdletBinding()]
  param([Parameter(Position = 0)][string]$Path = '.')

  $lsd = Get-LsdCommand
  if ($lsd) {
    & $lsd.Source --color always --icon always --oneline --long --almost-all --permission octal --date '+%Y%m%d-%H%M%S' $Path
    return
  }
  try { Get-ChildItemColor -Path $Path }
  catch { Get-ChildItem -Path $Path | Select-Object * | Format-Table -AutoSize -Wrap }
}

## 'sl' is a built-in alias for Set-Location. Remove it (if present) so our
## own sl function can take over. Guarded so re-sourcing (reload) doesn't throw.
if (Get-Alias -Name sl -ErrorAction Ignore) { Remove-Alias -Name sl -Force }

Function sl(){
  <#
  .SYNOPSIS
    Colored directory listing (replaces the built-in 'sl' Set-Location alias).
  .DESCRIPTION
    Uses 'lsd' when installed (long, octal permissions); otherwise lists via
    Get-ChildItemColor, falling back to a plain Get-ChildItem. The built-in 'sl'
    alias for Set-Location is removed above so this function takes over the name.
  .PARAMETER Path
    Directory to list (default: current directory).
  .EXAMPLE
    sl
    Show a colored listing of the current directory.
  #>
  [CmdletBinding()]
  param([Parameter(Position = 0)][string]$Path = '.')

  $lsd = Get-LsdCommand
  if ($lsd) {
    & $lsd.Source --color always --icon always --oneline --long --almost-all --permission octal $Path
    return
  }
  try { Get-ChildItemColor -Path $Path }
  catch { Get-ChildItem -Path $Path }
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

  # lsd first: size-sorted long listing with total (matches the zsh alias).
  # Keep the playful banner either way.
  $lsd = Get-LsdCommand

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
  [Console]::WriteLine((Get-Date -Format 'yyyyMMdd_HHmmss'))

  if ($lsd) {
    & $lsd.Source --color always --icon always --long --almost-all --total-size --sizesort --reverse --human-readable $Path
    return
  }

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
  Write-Output ("$($c.Cyan)Total size: {0} ({1:N0} bytes)$($c.Reset)" -f (Format-Size $total), [int64]$total)
}
