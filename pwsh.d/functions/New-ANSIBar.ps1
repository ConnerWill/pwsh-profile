## New-ANSIBar  --  from 22_functions_ansi.ps1 (one-file-per-function layout)

Function New-ANSIBar {
  [CmdletBinding()]
  Param(
      [Parameter(
        Mandatory,
        HelpMessage= "Enter a range of 256 color values, e.g. (232..255)"
      )]
      [ValidateNotNullOrEmpty()]
      [int[]]$Range,
      [Parameter(
        HelpMessage = "How many spaces do you want in the bar? This will increase the length of the bar."
      )]
      [int]$Spacing = 1
  )
  $esc = "$([char]0x1b)"
  $out = @()
  $blank = " "*$spacing
  $out += $range | ForEach-Object { "$esc[48;5;$($_)m$($blank)$esc[0m" }
  $out += $range | Sort-Object -Descending | ForEach-Object { "$esc[48;5;$($_)m$($blank)$esc[0m" }
  $out -join ""
}
