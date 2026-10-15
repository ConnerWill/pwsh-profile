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
  .PARAMETER Style
    Blocks (default) / Ansi / List / Table / All.
  .EXAMPLE
    Show-Colors
  .EXAMPLE
    Show-Colors -Style Ansi
  .EXAMPLE
    Show-Colors -Style All
  #>
  [CmdletBinding()]
  param(
    [ValidateSet('Blocks', 'Ansi', 'List', 'Table', 'All')]
    [string]$Style = 'Blocks'
  )

  $colors = [Enum]::GetValues([System.ConsoleColor])
  $e = "`e"

  function Script:_ShowBlocks {
    # 256-color block palette (formerly Get-ANSIColors).
    for ($i = 0; $i -le 255; $i++) {
      [Console]::Write(
        "$e[0;1;38;5;${i}m▌║█║▌│║▌│║▌║▌█║$e[0;38;5;${i}m▌│║▌║▌│║║▌█║▌║█$e[0m`n"
      )
    }
  }

  function Script:_ShowAnsi {
    # Shows the RENDERED sample AND the literal escape sequence you'd type.
    # '\e' is the ESC byte (char 27); use "`e" in PowerShell double-quotes.
    Write-Host "`nAttributes  (rendered  =  sequence):" -ForegroundColor Cyan
    $attrs = [ordered]@{ 1 = 'Bold'; 2 = 'Faint'; 3 = 'Italic'; 4 = 'Underline';
                         5 = 'Blink'; 7 = 'Reverse'; 9 = 'CrossedOut' }
    foreach ($a in $attrs.GetEnumerator()) {
      $rendered = "$e[$($a.Key)m$($a.Value)$e[0m"
      $literal  = "\e[$($a.Key)m"
      "{0,-28} = {1}" -f $rendered, $literal
    }

    Write-Host "`n256-color foreground  (rendered  =  sequence):" -ForegroundColor Cyan
    foreach ($i in 0, 1, 2, 9, 15, 33, 46, 196, 201, 208, 226, 244) {
      $rendered = "$e[38;5;${i}m  sample  $e[0m"
      "{0,-30} = \e[38;5;{1}m" -f $rendered, $i
    }
    Write-Host "  ... (any 0-255; use \e[38;5;Nm for fg, \e[48;5;Nm for bg)" -ForegroundColor DarkGray

    Write-Host "`nTruecolor (RGB) example:" -ForegroundColor Cyan
    "{0,-30} = \e[38;2;R;G;Bm" -f "$e[38;2;80;145;254m  sample  $e[0m"

    Write-Host "`nFull 256 fg palette:" -ForegroundColor Cyan
    for ($i = 0; $i -le 255; $i++) {
      [Console]::Write(("$e[38;5;{0}m{0,4}$e[0m" -f $i))
      if (($i + 1) % 16 -eq 0) { [Console]::Write("`n") }
    }

    Write-Host "`nFull 256 bg palette:" -ForegroundColor Cyan
    for ($i = 0; $i -le 255; $i++) {
      [Console]::Write(("$e[48;5;{0}m{0,4}$e[0m" -f $i))
      if (($i + 1) % 16 -eq 0) { [Console]::Write("`n") }
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
