## New-ANSIBar  --  from 22_functions_ansi.ps1 (one-file-per-function layout)
## Plus full-width line helpers built alongside New-ANSIBar:
##   draw_line  -- a full-width line: solid background-color bar (default), or a
##                 repeated-glyph rule via -Style / -Char.
##   line       -- tile one or more words/chars across the terminal width.
##   Get-ConsoleWidth -- shared width helper (console width, else 80).

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

## Shared width helper: current console width, falling back to 80 when
## unavailable (redirected output / no console).
Function Get-ConsoleWidth {
  $w = try { [Console]::WindowWidth } catch { 0 }
  if ($w -le 0) { $w = 80 }
  $w
}

Function draw_line {
  <#
  .SYNOPSIS
    Draw a single full-width line: a solid color bar, or a repeated-glyph rule.
  .DESCRIPTION
    Default mode fills the console width with a solid background-color bar
    (built on New-ANSIBar). Pass -Style for a repeated line-glyph rule, or -Char
    for an arbitrary glyph/word rule; both are colored with -Color.

    Line styles (-Style):
      1,4,8,9 : ─      2,3 : ═      5 : ▂      6 : ▄      7 : ▀      10 : #
  .PARAMETER Color
    256-color value for the line (default 46 = green).
  .PARAMETER Style
    Draw a repeated line-glyph rule using style index 1-10 instead of the solid
    background bar.
  .PARAMETER Char
    Draw a rule of this arbitrary string/glyph instead of the solid bar.
  .EXAMPLE
    draw_line
    Solid green full-width background bar (default).
  .EXAMPLE
    draw_line 196
    Solid red background bar.
  .EXAMPLE
    draw_line -Style 2 -Color 198
    Double '═' rule in pink (256-color 198).
  .EXAMPLE
    draw_line -Char '#'
    A '#' rule across the width.
  #>
  [CmdletBinding(DefaultParameterSetName = 'Bar')]
  Param(
      [Parameter(Position = 0)]
      [int]$Color = 46,

      [Parameter(ParameterSetName = 'Style')]
      [ValidateRange(1, 10)]
      [int]$Style,

      [Parameter(ParameterSetName = 'Char')]
      [string]$Char
  )

  $width = Get-ConsoleWidth

  switch ($PSCmdlet.ParameterSetName) {
    'Bar' {
      # Solid background-color bar (original behavior).
      New-ANSIBar -Range $Color -Spacing $width
    }
    default {
      # Repeated-glyph rule. Pick the glyph from -Style or use -Char verbatim.
      $glyph = if ($PSCmdlet.ParameterSetName -eq 'Char') { $Char }
        else {
          switch ($Style) {
            2 { '═' } 3 { '═' } 5 { '▂' } 6 { '▄' } 7 { '▀' } 10 { '#' }
            default { '─' }   # 1,4,8,9
          }
        }
      if ([string]::IsNullOrEmpty($glyph)) { $glyph = '─' }
      $body = ($glyph * [math]::Ceiling($width / $glyph.Length)).Substring(0, $width)
      $esc  = "$([char]0x1b)"
      "$esc[38;5;${Color}m$body$esc[0m"
    }
  }
}

Function line {
  <#
  .SYNOPSIS
    Tile one or more words/characters across the terminal width.
  .DESCRIPTION
    Repeats each supplied word across the full console width and prints it on its
    own line (like the bash 'line'). With no argument, draws a single '─' rule.
  .PARAMETER Word
    One or more strings to tile across the width (default '─').
  .EXAMPLE
    line
    Draw a single '─' rule the width of the terminal.
  .EXAMPLE
    line '─' '*'
    Draw two rules: one of '─', one of '*'.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [string[]]$Word = @('─')
  )
  $cols = Get-ConsoleWidth
  foreach ($w in $Word) {
    if ([string]::IsNullOrEmpty($w)) { $w = '─' }
    $repeat = [math]::Ceiling($cols / $w.Length)
    ($w * $repeat).Substring(0, $cols)
  }
}
