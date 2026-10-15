## Show-Colors  --  one entry point for the color/ANSI demos.
##   Ansi  (default) -> text attributes + 256-color fore/background palette
##   List            -> the 16 console colors, one per line
##   Table           -> every foreground on every background
##   All             -> all of the above
## (Get-ANSIColors stays its own standalone function.)

Function Show-Colors {
  <#
  .SYNOPSIS
    Show color/ANSI references. Defaults to the ANSI style.
  .PARAMETER Style
    Ansi (default) / List / Table / All.
  .EXAMPLE
    Show-Colors
  .EXAMPLE
    Show-Colors -Style List
  .EXAMPLE
    Show-Colors -Style All
  #>
  [CmdletBinding()]
  param(
    [ValidateSet('Ansi', 'List', 'Table', 'All')]
    [string]$Style = 'Ansi'
  )

  $colors = [Enum]::GetValues([System.ConsoleColor])
  $e = "`e"

  function Script:_ShowAnsi {
    # Text attributes.
    Write-Host "`nAttributes:" -ForegroundColor Cyan
    $attrs = [ordered]@{ 1 = 'Bold'; 2 = 'Faint'; 3 = 'Italic'; 4 = 'Underline';
                         5 = 'Blink'; 7 = 'Reverse'; 9 = 'CrossedOut' }
    foreach ($a in $attrs.GetEnumerator()) {
      [Console]::Write("$e[$($a.Key)m$($a.Value)$e[0m  ")
    }
    Write-Host "`n"

    # 256-color foreground palette.
    Write-Host "256-color foreground:" -ForegroundColor Cyan
    for ($i = 0; $i -le 255; $i++) {
      [Console]::Write(("$e[38;5;{0}m{0,4}$e[0m" -f $i))
      if (($i + 1) % 16 -eq 0) { [Console]::Write("`n") }
    }
    Write-Host ""

    # 256-color background palette.
    Write-Host "256-color background:" -ForegroundColor Cyan
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
    'Ansi'  { _ShowAnsi }
    'List'  { _ShowList }
    'Table' { _ShowTable }
    'All'   { _ShowAnsi; _ShowList; _ShowTable }
  }
}

## Back-compat wrappers so the old names keep their exact behavior.
Function Show-ColorList  { Show-Colors -Style List }
Function Show-ColorTable { Show-Colors -Style Table }
