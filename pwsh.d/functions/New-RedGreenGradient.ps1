## New-RedGreenGradient  --  from 22_functions_ansi.ps1 (one-file-per-function layout)

Function New-RedGreenGradient {
    <#
    .SYNOPSIS
      Build a red-to-green ANSI gradient bar string.
    .DESCRIPTION
      Produces a colored bar (24-bit ANSI) that transitions from red through
      yellow to green. Useful for visualizing a percentage, health, or score.
      The -Percent controls how far along the red->green ramp the bar goes.
    .PARAMETER Percent
      How far to fill the gradient, as a decimal 0.0-1.0 (default 1.0 = full green).
    .PARAMETER Step
      Relative bar length / smoothness, 2-10. Smaller = longer, smoother bar
      (default 5).
    .PARAMETER Character
      The character used to draw the bar (default full block U+2588).
    .EXAMPLE
      New-RedGreenGradient
      A full red-to-green bar.
    .EXAMPLE
      New-RedGreenGradient -Percent 0.5
      A bar that stops around the yellow midpoint.
    .EXAMPLE
      New-RedGreenGradient -Step 2 -Character '='
      A long, smooth bar drawn with '='.
    #>
    [cmdletbinding()]
    [OutputType([System.String])]

    Param(
        [Parameter(
          Position = 0,
          HelpMessage = "Specify a percentage as a decimal value: 0.0-1.0 (Default: 1.0)")]
        [ValidateScript( {$_ -le 1})]
        [double]$Percent = 1,

        [Parameter(
          HelpMessage = "Specify a relative bar length between 2-10. The smaller the number the longer the bar. (Default: 5)")]
        [ValidateRange(2, 10)]
        [int]$Step = 5,

        [Parameter(
          HelpMessage = "Specify a character to use for the gradient bar (Default: 0x2588)")]
        [char]$Character = 0x2588
    )

    Write-Verbose "Starting $($MyInvocation.MyCommand)"
    $r = 255; $g = 0

    Write-Verbose "Using a percentage of $Percent"
    [int]$max = $r*$Percent

    Write-Verbose "Using a calculated max value of $max"
    [string[]]$out = @()

    Write-Verbose "Looping from through with a step value of $step"
    for ($i = 0; $i -le $max; $i += $Step) {
        $out += "$([char]0x1b)[38;2;$r;$g;0m$Character$([char]0x1b)[0m"
        $r -= $Step; $g += $Step
        if ($g -ge 256) {
            Write-Verbose "100% green has been reached"
            break
        }
    }

    Write-Verbose "Creating final ANSI gradient bar"
    $out -join ""

    Write-Verbose "Ending $($MyInvocation.MyCommand)"
} #end function
