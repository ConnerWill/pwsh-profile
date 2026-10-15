## New-RedGreenGradient  --  from 22_functions_ansi.ps1 (one-file-per-function layout)

Function New-RedGreenGradient {
    <#
    .SYNOPSIS
      Build an ANSI gradient bar string between two colors (defaults red->green).
    .DESCRIPTION
      Produces a 24-bit ANSI colored bar that smoothly interpolates from a start
      color to an end color. By default it goes red -> green (useful for
      visualizing a percentage, health, or score), but any two colors can be
      supplied via -StartColor / -EndColor as #RRGGBB hex. The -Percent controls
      how far along the gradient the bar is drawn.
    .PARAMETER Percent
      How far to fill the gradient, as a decimal 0.0-1.0 (default 1.0 = full bar
      ending at EndColor).
    .PARAMETER Step
      Relative bar length / smoothness, 2-10. Smaller = longer, smoother bar
      (default 5).
    .PARAMETER Character
      The character used to draw the bar (default full block U+2588).
    .PARAMETER StartColor
      Hex color (#RRGGBB) the gradient starts from (default '#FF0000', red).
    .PARAMETER EndColor
      Hex color (#RRGGBB) the gradient ends at (default '#00FF00', green).
    .EXAMPLE
      New-RedGreenGradient
      A full red-to-green bar (the default).
    .EXAMPLE
      New-RedGreenGradient -Percent 0.5
      A bar filled halfway along the gradient.
    .EXAMPLE
      New-RedGreenGradient -StartColor '#000AFF' -EndColor '#00FFF7'
      A blue-to-cyan gradient.
    .EXAMPLE
      New-RedGreenGradient -StartColor '#FF8800' -EndColor '#8800FF' -Step 2 -Character '='
      A long, smooth orange-to-purple bar drawn with '='.
    #>
    [cmdletbinding()]
    [OutputType([System.String])]

    Param(
        [Parameter(
          Position = 0,
          HelpMessage = "Specify a percentage as a decimal value: 0.0-1.0 (Default: 1.0)")]
        [ValidateRange(0, 1)]
        [double]$Percent = 1,

        [Parameter(
          HelpMessage = "Specify a relative bar length between 2-10. The smaller the number the longer the bar. (Default: 5)")]
        [ValidateRange(2, 10)]
        [int]$Step = 5,

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

    # Number of segments: a larger -Step -> fewer (chunkier) segments, matching
    # the original behavior where Step controlled bar length/smoothness.
    [int]$segments = [math]::Max(1, [int](255 / $Step))
    [int]$filled   = [int]([math]::Round($segments * $Percent))
    Write-Verbose "Drawing $filled of $segments segments at $([int]($Percent*100))%"

    [string[]]$out = @()
    for ($i = 0; $i -lt $filled; $i++) {
        # Interpolation factor 0..1 across the (filled portion of the) bar.
        $t = if ($segments -le 1) { 0 } else { $i / ($segments - 1) }
        $r = [int][math]::Round($from[0] + ($to[0] - $from[0]) * $t)
        $g = [int][math]::Round($from[1] + ($to[1] - $from[1]) * $t)
        $b = [int][math]::Round($from[2] + ($to[2] - $from[2]) * $t)
        $out += "$([char]0x1b)[38;2;$r;$g;${b}m$Character$([char]0x1b)[0m"
    }

    Write-Verbose "Creating final ANSI gradient bar"
    $out -join ""

    Write-Verbose "Ending $($MyInvocation.MyCommand)"
} #end function
