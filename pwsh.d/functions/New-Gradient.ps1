## New-Gradient  --  from 22_functions_ansi.ps1 (one-file-per-function layout)
## (formerly New-RedGreenGradient; that name is kept as an alias.)

Function New-Gradient {
    <#
    .SYNOPSIS
      Build an ANSI gradient bar string between two colors (defaults red->green).
    .DESCRIPTION
      Produces a 24-bit ANSI colored bar that smoothly interpolates from a start
      color to an end color across a given width. By default it goes red -> green
      (useful for visualizing a percentage, health, or score), but any two colors
      can be supplied via -StartColor / -EndColor as #RRGGBB hex. -Width sets how
      many characters wide the bar is (defaults to the current console width), and
      -Percent controls how far along that width the bar is actually filled.

      Aliased as 'gradient' and 'New-RedGreenGradient' (the former name).
    .PARAMETER Percent
      How far to fill the bar, as a decimal 0.0-1.0 (default 1.0 = full width,
      ending at EndColor).
    .PARAMETER Width
      Total bar width in characters (default: the current console width).
    .PARAMETER Character
      The character used to draw the bar (default full block U+2588).
    .PARAMETER StartColor
      Hex color (#RRGGBB) the gradient starts from (default '#FF0000', red).
    .PARAMETER EndColor
      Hex color (#RRGGBB) the gradient ends at (default '#00FF00', green).
    .EXAMPLE
      New-Gradient
      A full-width red-to-green bar across the console.
    .EXAMPLE
      New-Gradient -Percent 0.5
      Fill the first half of a full-width gradient.
    .EXAMPLE
      New-Gradient -Width 20 -StartColor '#000AFF' -EndColor '#00FFF7'
      A 20-wide blue-to-cyan gradient.
    .EXAMPLE
      gradient -StartColor '#FF8800' -EndColor '#8800FF' -Character '='
      An orange-to-purple bar drawn with '=' (via the 'gradient' alias).
    #>
    [cmdletbinding()]
    [OutputType([System.String])]
    [Alias('gradient', 'New-RedGreenGradient')]

    Param(
        [Parameter(
          Position = 0,
          HelpMessage = "Specify a percentage as a decimal value: 0.0-1.0 (Default: 1.0)")]
        [ValidateRange(0, 1)]
        [double]$Percent = 1,

        [Parameter(
          Position = 1,
          HelpMessage = "Total bar width in characters (Default: current console width)")]
        [ValidateRange(1, 10000)]
        [int]$Width,

        [Parameter(
          HelpMessage = "Specify a character to use for the gradient bar (Default: 0x2588)")]
        [char]$Character = 0x2588,

        [Parameter(
          HelpMessage = "Hex color (#RRGGBB) the gradient starts from (Default: #FF0000)")]
        [ValidatePattern('^#?[0-9A-Fa-f]{6}$')]
        [string]$StartColor = '#FF0000',

        [Parameter(
          HelpMessage = "Hex color (#RRGGBB) the gradient ends at (Default: #00FF00)")]
        [ValidatePattern('^#?[0-9A-Fa-f]{6}$')]
        [string]$EndColor = '#00FF00'
    )

    Write-Verbose "Starting $($MyInvocation.MyCommand)"

    # Default the width to the console width when not supplied.
    if (-not $PSBoundParameters.ContainsKey('Width')) {
        $Width = try { [Console]::WindowWidth } catch { 0 }
        if ($Width -le 0) { $Width = 80 }
        Write-Verbose "Width defaulted to console width: $Width"
    }

    # Parse the two endpoint colors into RGB integer triples.
    function ConvertFrom-Hex([string]$hex) {
        $h = $hex.TrimStart('#')
        [int]('0x' + $h.Substring(0, 2)),
        [int]('0x' + $h.Substring(2, 2)),
        [int]('0x' + $h.Substring(4, 2))
    }
    $from = ConvertFrom-Hex $StartColor
    $to   = ConvertFrom-Hex $EndColor
    Write-Verbose "Gradient from RGB($($from -join ',')) to RGB($($to -join ','))"

    [int]$filled = [int]([math]::Round($Width * $Percent))
    Write-Verbose "Drawing $filled of $Width cells at $([int]($Percent*100))%"

    [string[]]$out = @()
    for ($i = 0; $i -lt $filled; $i++) {
        # Interpolate 0..1 across the FULL width so colors stay anchored even
        # when only part of the bar is filled.
        $t = if ($Width -le 1) { 0 } else { $i / ($Width - 1) }
        $r = [int][math]::Round($from[0] + ($to[0] - $from[0]) * $t)
        $g = [int][math]::Round($from[1] + ($to[1] - $from[1]) * $t)
        $b = [int][math]::Round($from[2] + ($to[2] - $from[2]) * $t)
        $out += "$([char]0x1b)[38;2;$r;$g;${b}m$Character$([char]0x1b)[0m"
    }

    Write-Verbose "Creating final ANSI gradient bar"
    $out -join ""

    Write-Verbose "Ending $($MyInvocation.MyCommand)"
} #end function
