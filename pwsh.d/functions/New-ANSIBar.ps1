## New-ANSIBar  --  from 22_functions_ansi.ps1 (one-file-per-function layout)
## Plus draw_line: a simple full-width colored line built on New-ANSIBar.

Function New-ANSIBar {
  <#
  .SYNOPSIS
    Build a colored bar from a range of 256-colors.
  .DESCRIPTION
    Renders each color in -Range as a block of -Spacing spaces. When the range
    has more than one color it sweeps forward then back (a gradient). A single
    color draws one solid bar (no doubling), which makes it handy for drawing a
    full-width line via draw_line.
  .PARAMETER Range
    256-color values (e.g. 232..255). Defaults to a single mid-grey (244).
  .PARAMETER Spacing
    Width (in spaces) of each color block.
  .EXAMPLE
    New-ANSIBar -Range (232..255)
  .EXAMPLE
    New-ANSIBar -Range 46 -Spacing ([Console]::WindowWidth)
  #>
  [CmdletBinding()]
  Param(
      [Parameter(HelpMessage = "256-color values, e.g. (232..255). Defaults to a single color.")]
      [ValidateNotNullOrEmpty()]
      [int[]]$Range = @(244),

      [Parameter(HelpMessage = "Width (spaces) of each color block.")]
      [int]$Spacing = 1
  )
  $esc = "$([char]0x1b)"
  $blank = " " * $Spacing
  $out = @()
  $out += $Range | ForEach-Object { "$esc[48;5;$($_)m$blank$esc[0m" }
  # Only mirror the sweep when there's an actual gradient (>1 color), so a
  # single color produces exactly one bar instead of a doubled-width one.
  if ($Range.Count -gt 1) {
    $out += $Range | Sort-Object -Descending | ForEach-Object { "$esc[48;5;$($_)m$blank$esc[0m" }
  }
  $out -join ""
}

Function draw_line {
  <#
  .SYNOPSIS
    Draw a single full-width line in a given 256-color.
  .DESCRIPTION
    Thin wrapper over New-ANSIBar that fills the full console width with one
    color. Defaults to green (46).
  .PARAMETER Color
    256-color value for the line (default 46 = green).
  .EXAMPLE
    draw_line
  .EXAMPLE
    draw_line 196      # red full-width line
  #>
  [CmdletBinding()]
  Param(
      [Parameter(Position = 0)]
      [int]$Color = 46
  )
  # Full console width; fall back to 80 if the width can't be determined
  # (e.g. redirected output / no console).
  $width = try { [Console]::WindowWidth } catch { 0 }
  if ($width -le 0) { $width = 80 }

  New-ANSIBar -Range $Color -Spacing $width
}
