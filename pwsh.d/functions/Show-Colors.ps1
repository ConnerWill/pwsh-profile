## Show-Colors  --  one entry point for the color/ANSI demos.
##   Ansi  (default) -> ANSI escape-sequence reference (via Show-ANSISequence)
##   List            -> the 16 console colors, one per line
##   Table           -> every foreground on every background
##   All             -> all of the above
## (Get-ANSIColors stays its own standalone function.)

Function Show-Colors {
  <#
  .SYNOPSIS
    Show color/ANSI references. Defaults to the ANSI escape sequences.
  .PARAMETER Style
    Ansi (default) / List / Table / All.
  .EXAMPLE
    Show-Colors            # ANSI escape sequences
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
    'Ansi'  { if (Get-Command Show-ANSISequence -EA Ignore) { Show-ANSISequence } else { _ShowList } }
    'List'  { _ShowList }
    'Table' { _ShowTable }
    'All'   {
      if (Get-Command Show-ANSISequence -EA Ignore) { Show-ANSISequence }
      _ShowList
      _ShowTable
    }
  }
}

## Back-compat wrappers so the old names keep their exact behavior.
Function Show-ColorList  { Show-Colors -Style List }
Function Show-ColorTable { Show-Colors -Style Table }
