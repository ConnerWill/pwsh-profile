## Show-ColorTable  --  from 22_functions_ansi.ps1 (one-file-per-function layout)

function Show-ColorTable {
  # aka Show-ColorsANSI
  $colors = [enum]::GetValues([System.ConsoleColor])
  Foreach ($bgcolor in $colors){
      Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|"  -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
      Write-Host " on $bgcolor"
  }
}

## Show-ColorList
