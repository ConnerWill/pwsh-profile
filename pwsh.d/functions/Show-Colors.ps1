## Show-Colors  --  one entry point for the color/ANSI demos.
##   Blocks (default) -> the 256-color block palette (was Get-ANSIColors)
##   Ansi             -> text attributes + 256-color fore/background palette
##   List             -> the 16 console colors, one per line
##   Table            -> every foreground on every background
##   All              -> all of the above
## Get-ANSIColors is kept as a wrapper for 'Show-Colors -Style Blocks'.

Function Show-Colors {
  <#
  .SYNOPSIS
    Show color/ANSI references. Defaults to the 256-color block palette.
  .DESCRIPTION
    A single entry point for the color/ANSI demos. The -Style parameter selects
    which reference to render:
      Blocks (default) - the 256-color block palette (indexed), also available
                         as Get-ANSIColors.
      Ansi             - text attributes (bold, underline, ...) plus the 256-color
                         foreground and background palettes, showing each escape.
      List             - the 16 console colors, one per line.
      Table            - every foreground color on every background color.
      All              - render all of the above in sequence.
  .PARAMETER Style
    Which reference to show: Blocks (default) / Ansi / List / Table / All.
  .EXAMPLE
    Show-Colors
    Show the default 256-color block palette.
  .EXAMPLE
    Show-Colors -Style Ansi
    Show text attributes and the fore/background 256-color palettes with escapes.
  .EXAMPLE
    Show-Colors -Style Table
    Show every foreground color on every background color.
  .EXAMPLE
    Show-Colors -Style All
    Render every reference in sequence.
  #>
  [CmdletBinding()]
  param(
    [ValidateSet('Blocks', 'Ansi', 'List', 'Table', 'All')]
    [string]$Style = 'Blocks'
  )

  $colors = [Enum]::GetValues([System.ConsoleColor])
  $e = "`e"

  function Script:_ShowBlocks {
    # 256-color block palette (formerly Get-ANSIColors), now labeled with the
    # color index and the literal escape sequence for that color.
    $t = '`e'   # literal text for the ESC byte
    for ($i = 0; $i -le 255; $i++) {
      $bars = "$e[0;1;38;5;${i}m▌║█║▌│║▌│║▌║▌█║$e[0;38;5;${i}m▌│║▌║▌│║║▌█║▌║█$e[0m"
      $label = "$e[38;5;${i}m{0,3}  $t[38;5;${i}m$e[0m" -f $i
      [Console]::WriteLine("$bars  $label")
    }
  }

  function Script:_ShowAnsi {
    # Faithful to the original Show-ANSISequence: print the LITERAL escape-code
    # text (e.g. `e[1mBold`e[0m) *rendered in that very style*, so each line
    # shows both what the sequence looks like AND the code itself.
    # (Original used an Add-Border header that no longer exists -> plain header.)
    $t = '`e'   # the literal text shown for the ESC byte

    function _hdr($label) {
      $cy = if ($Colors) { $Colors.Cyan } else { "`e[38;5;87m" }
      $rs = if ($Colors) { $Colors.Reset } else { "`e[0m" }
      [Console]::WriteLine("`n${cy}--- $label ---${rs}")
    }

    _hdr 'Basic Sequences'
    $basic = [ordered]@{ 1='Bold'; 2='Faint'; 3='Italic'; 4='Underline';
                         5='SlowBlink'; 6='RapidBlink'; 7='Reverse'; 9='CrossedOut' }
    foreach ($b in $basic.GetEnumerator()) {
      $seq = "$t[$($b.Key)m$($b.Value)$t[0m"      # literal text
      [Console]::WriteLine("$e[$($b.Key)m$seq$e[0m")  # rendered in that style
    }

    _hdr 'Foreground (simple)'
    foreach ($n in @(30..37) + @(90..97)) {
      $seq = "$t[${n}mHello$t[0m"
      [Console]::Write("$e[${n}m$seq$e[0m   ")
    }
    Write-Host ""

    _hdr '8-Bit Foreground'
    for ($i = 0; $i -le 255; $i++) {
      $seq = "$t[38;5;${i}mHello$t[0m"
      [Console]::Write("$e[38;5;${i}m$seq$e[0m  ")
      if (($i + 1) % 4 -eq 0) { [Console]::Write("`n") }
    }
    Write-Host ""

    _hdr 'Background (simple)'
    foreach ($n in @(40..47) + @(100..107)) {
      $seq = "$t[${n}mHello$t[0m"
      [Console]::Write("$e[1;${n}m$seq$e[0m   ")
    }
    Write-Host ""

    _hdr '8-Bit Background'
    for ($i = 0; $i -le 255; $i++) {
      $seq = "$t[48;5;${i}mHello$t[0m"
      [Console]::Write("$e[1;48;5;${i}m$seq$e[0m  ")
      if (($i + 1) % 4 -eq 0) { [Console]::Write("`n") }
    }
    Write-Host ""
  }

  function Script:_ShowList {
    $max = ($colors | ForEach-Object { "$_ ".Length } | Measure-Object -Maximum).Maximum
    foreach ($color in $colors) {
      Write-Host (" {0,2} {1,$max} " -f [int]$color, $color) -NoNewline
      Write-Host "$color" -ForegroundColor $color
    }
  }

  function Script:_ShowTable {
    foreach ($bg in $colors) {
      foreach ($fg in $colors) {
        Write-Host "$fg|" -ForegroundColor $fg -BackgroundColor $bg -NoNewline
      }
      Write-Host " on $bg"
    }
  }

  switch ($Style) {
    'Blocks' { _ShowBlocks }
    'Ansi'   { _ShowAnsi }
    'List'   { _ShowList }
    'Table'  { _ShowTable }
    'All'    { _ShowBlocks; _ShowAnsi; _ShowList; _ShowTable }
  }
}

## Back-compat wrappers so the old names keep working.
Function Get-ANSIColors { Show-Colors -Style Blocks }
Function Show-ColorList  { Show-Colors -Style List }
Function Show-ColorTable { Show-Colors -Style Table }
