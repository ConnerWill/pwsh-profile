## Convert-HexToAnsi  --  from 22_functions_ansi.ps1 (one-file-per-function layout)

Function Convert-HexToAnsi {
    <#
    .SYNOPSIS
      Convert an HTML hex color code to a 24-bit ANSI foreground escape sequence.
    .DESCRIPTION
      Takes a #RRGGBB hex color and returns the raw ANSI escape string that sets
      that color as the terminal foreground, e.g. for use in prompts or Write-Host.
    .PARAMETER HtmlCode
      An HTML hex color like '#13A10E'. Accepts pipeline input.
    .EXAMPLE
      Convert-HexToAnsi '#13A10E'
      Returns the ANSI sequence for that green.
    .EXAMPLE
      '#FF8800' | cha
      Pipe a hex code through the 'cha' alias.
    .EXAMPLE
      "$(Convert-HexToAnsi '#51A3FF')Hello`e[0m"
      Embed the sequence inline to color text.
    #>
    [cmdletbinding()]
    [OutputType("System.String")]
    [alias("cha")]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            HelpMessage = "Specify an HTML hex color code like #13A10E"
        )]
        [ValidatePattern('^#\w{6}$')]
        [alias("code")]
        [string]$HtmlCode
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Converting $HTMLCode"
        $code = [System.Drawing.ColorTranslator]::FromHtml($htmlCode)

        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] RGB = $($code.r),$($code.g),$($code.b)"
        $ansi = '[38;2;{0};{1};{2}m' -f $code.R,$code.G,$code.B

        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Outputting $ansi"
        $ansi
    } #process
    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"
    } #end
} #close Convert-HTMLtoANSI
