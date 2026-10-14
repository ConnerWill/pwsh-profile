## Loaded by profile.ps1 pwsh.d loader. Split from the old 03/05_functions.ps1.

###{{{ ANSI / COLOR FUNCTIONS

function Get-ANSIColors(){
  for($i=0; $i -le 255 ; $i++){
    [Console]::Write(
      "`e[0;1;38;5;${i}m▌║█║▌│║▌│║▌║▌█║``e[0;38;5;${i}m▌│║▌║▌│║║▌█║▌║█`e[0m`n"
    )
  }
}

function Blink-Message {
<#
  .SYNOPSIS
    Display blinking colored output.

  .DESCRIPTION
    This function is used to output a message to the screen which is
    blinking and looping through a set of predefined or provided colors.

    This function provides a simple way to output blinking colored text.

  .PARAMETER Message
    The message to display in blinking colors

  .PARAMETER Delay
    The speed (sleep time in milliseconds) between color changes (Default: 250)

  .PARAMETER Count
    The number of 'blinks' to perform (Default: 12)

  .PARAMETER Colors
    The human name for colors to loop through
     (Default: Red Yellow DarkYellow Green DarkGreen DarkCyan Cyan Blue DarkBlue DarkMagenta Magenta White Black)

  .EXAMPLE
    PS C:\> . Import-ModuleFile -File $function.FullName

    Imports the file stored in $function according to import policy

  .LINK
    https://social.technet.microsoft.com/forums/windowsserver/en-US/3e9585cf-bbed-4e8e-80ba-65fd0a3a71d5/flashing-text-in-powershell

  .LINK
    http://github.com/ConnerWill


#>
  [CmdletBinding()]
  Param(
    [Parameter(
      HelpMessage= "Enter the message/data to display in blinking colors",
      Position = 0,
      ValueFromPipeline = $True,
      ValueFromRemainingArguments = $True)]
      [ValidateNotNullOrEmpty()]
      [Alias("input","text")]
      [String]$Message,

    [Parameter(
      HelpMessage= "Enter The speed (sleep time) between color changes (blinks)",
      Position = 1)]
      [Alias("sleep","sleeptime")]
      [int]$Delay = 250 ,

    [Parameter(
      HelpMessage= "Enter the number of blinks to perform",
      Position = 2)]
      [Alias("blinks","itr")]
      [int]$Count = 12,

    [Parameter(
      HelpMessage= "Enter the 'human name' for colors to loop through (e.g. Red Green Blue)",
      ValueFromRemainingArguments = $True)]
      [ValidateNotNullOrEmpty()]
      [SupportsWildcards()]
      [Alias("colors","rgb")]
      [ConsoleColor[]]$Colors #= @(Red, Yellow, DarkYellow, Green, DarkGreen, DarkCyan, Cyan, Blue, DarkBlue, DarkMagenta, Magenta, White)
      #[System.ConsoleColor]$ForegroundColor #[System.ConsoleColor]$BackgroundColor
  )
    $startColor = [Console]::ForegroundColor
    $startLeft  = [Console]::CursorLeft
    $startTop   = [Console]::CursorTop
    $colorCount = $Colors.Length
    [Console]::CursorVisible = $False
    for($i = 0; $i -lt $Count; $i++) {
        [Console]::CursorLeft = $startLeft
        [Console]::CursorTop  = $startTop
        [Console]::ForegroundColor = $Colors[$($i % $colorCount)]
        [Console]::Write($Message)
        Start-Sleep -Milliseconds $Delay
    }
    [Console]::ForegroundColor = $startColor
    [Console]::CursorVisible = $True
}

Function Convert-HexToAnsi {
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

Function New-RedGreenGradient {
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

Function Show-ANSISequence {
    [cmdletbinding(DefaultParameterSetName = "basic")]
    [outputtype([system.string])]

    Param(
        [Parameter(
            ParameterSetName = "basic",
            HelpMessage = "Display basic ANSI escape sequences. This is the default setting.")]
        [switch]$Basic,

        [Parameter(
            ParameterSetName = "foreback",
            HelpMessage = "Display foreground ANSI escape sequences")]
        [switch]$Foreground,

        [Parameter(
            ParameterSetName = "foreback",
            HelpMessage = "Display background ANSI escape sequences")]
        [switch]$Background,

        [Parameter(
            ParameterSetName = "foreback")]
        [ValidateSet("All", "Simple", "8Bit")]
        [string]$Type = "All",

        [Parameter(
            ParameterSetName = "RGB",
            HelpMessage = "Specify an array of RGB values between 0 and 255")]
        [int[]]$RGB,

        [Parameter(
            HelpMessage = "Show the value as an unformatted string")]
        [switch]$AsString
    )

    Write-Verbose "Starting $($myinvocation.MyCommand)"
    Write-Debug "Using parameter set $($PSCmdlet.ParameterSetName)"
    Write-Debug "Bound parameters"
    $PSBoundParameters | Out-String | Write-Debug

    #default to Basic even if the user doesn't specify the -Basic parameter
    if ($PSCmdlet.parametersetname -eq 'basic') {
        $Basic = $True
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'foreback') {
        Write-Debug "Testing bound parameters"
        #9/15/2022 Fixed logic to avoid including Foreground unless specified. Issue #130 JDH
        if ( (-Not ($PSBoundParameters.ContainsKey('foreground'))) -AND (-Not ($PSBoundParameters.ContainsKey('background')))) {
            #default to foreground Issue # 110
            Write-Debug "Setting Foreground as default"
            $Foreground = $True
        }
    }

    # a private function to display results in columns on the screen
    Function display {
        Param([object]$all, [int]$Max)

        $c = 1
        [string]$row = ""

        for ($i = 0; $i -le $all.count; $i++) {
            if ($c -gt $max) {
                $row
                $c = 1
                $row = ""
                #need to reset $i otherwise the entry gets omitted
                # Issue #125
                $i--
            }
            else {
                $row += "$($all[$i]) `t"
                $c++
            }
        }
    } #display function

    if ($IsCoreCLR) {
        Write-Debug "CoreCLR"
        $esc = "`e"
        $escText = '`e'
        $max = 3
    }
    else {
        Write-Debug "Desktop"
        $esc = $([char]27)
        $escText = '$([char]27)'
        $max = 2
    }

    #region basic
    if ($basic) {
        Write-Debug "Get basic settings"
        Add-Border "Basic Sequences" -ANSIText "$esc[1m" | Write-Host

        $basichash = @{
            1 = "Bold"
            2 = "Faint"
            3 = "Italic"
            4 = "Underline"
            5 = "SlowBlink"
            6 = "RapidBlink"
            7 = "Reverse"
            9 = "CrossedOut"
        }

        $basichash.GetEnumerator() | ForEach-Object {
            $sequence = "$esctext[$($_.name)m$($_.value)$esctext[0m"
            if ($AsString) {
                $sequence
            }
            else {
                "$esc[$($_.name)m$sequence$esc[0m"
            }
        }
    }
    #endregion

    #region foreground

    If ($Foreground) {
        Write-Debug "Getting foreground"
        if ($Type -match "All|Simple") {
            Add-Border "Foreground" -ANSIText "$esc[93m" | Write-Host
            $n = [System.Collections.Generic.list[int]]::new()
            30..37 | ForEach-Object {$n.Add($_)}
            90..97 | ForEach-Object {$n.Add($_)}

            $all = $n | ForEach-Object {
                $sequence = "$esctext[$($_)mHello$esctext[0m"
                if ($AsString) {
                    $sequence
                }
                else {
                    "$esc[$($_)m$sequence$esc[0m"
                }
            }

            display -all $all -Max $max

            Write-Host "`n"
        }
        if ($Type -match "All|8bit") {
            Add-Border "8-Bit Foreground" -ANSIText "$esc[38;5;10m" | Write-Host
            $all = 1..255 | ForEach-Object {
                $sequence = "$esctext[38;5;$($_)mHello$esctext[0m"
                if ($AsString) {
                    $sequence
                }
                else {
                    "$esc[38;5;$($_)m$sequence$esc[0m"
                }
            }
            display -all $all -Max $max
        }
    }
    #endregion

    #region background
    If ($Background) {
        Write-Debug "Getting background"
        if ($Type -match "All|Simple") {
            Add-Border "Background" -ANSIText "$esc[46m" | Write-Host
            $n = 40..47
            $n += 100..107
            $all = $n | ForEach-Object {
                $sequence = "$esctext[$($_)mHello$esctext[0m"
                if ($AsString) {
                    $sequence
                }
                else {
                    "$esc[1;$($_)m$sequence$esc[0m"
                }
            }

            display -all $all -Max $max

            Write-Host "`n"
        }

        if ($Type -match "All|8bit") {
            Add-Border "8-Bit Background" -ANSIText "$esc[7;38;5;10m" | Write-Host
            $all = 1..255 | ForEach-Object {
                $sequence = "$esctext[48;5;$($_)mHello$esctext[0m"
                if ($AsString) {
                    $sequence
                }
                else {
                    "$esc[1;48;5;$($_)m$sequence$esc[0m"
                }
            }
            display -all $all -Max $max
        }
    }

    #endregion

    #region RGB

    if ($RGB) {
        Write-Debug "Using RBG values"
        if ($rgb.count -ne 3) {
            Write-Warning "Wrong number of arguments. Specify RED,GREEN and BLUE values"
            return
        }
        $test = $rgb | Where-Object { $_ -gt 255 }
        if ($test.count -gt 0) {
            Write-Warning "Detected a value above 255"
            return $rgb
        }

        $r = $rgb[0]
        $g = $rgb[1]
        $b = $rgb[2]

        Write-Host "`r"
        $sequence = "$esctext[38;2;$r;$g;$($b)m256 Color (R:$r)(G:$g)(B:$b)$esctext[0m"
        if ($AsString) {
            $sequence
        }
        else {
            "$esc[38;2;$r;$g;$($b)m$sequence$esc[0m"
        }

    }
    #endregionm

    #insert a blank line to set off the results
    Write-Host "`r"

    Write-Verbose "Ending $($myinvocation.MyCommand)"
}

Function Out-ConditionalColor {
    [cmdletbinding(DefaultParameterSetName = "property")]
    [alias("occ")]

    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Enter an hashtable of conditional properties and colors.",
            ParameterSetName = "property"
        )][ValidateScript({
                #validate colors
                $allowed = [enum]::GetNames([system.consolecolor])
                $bad = $_.Values | Where-Object { $allowed -notcontains $_ }
                if ($bad) { $valid = $allowed -join ','; Throw "You are using one or more invalid colors: $($bad -join ','). Valid colors are $Valid" }
                else { $True }
        })][hashtable]$PropertyConditions,

        [Parameter(
            Position = 1,
            Mandatory,
            HelpMessage = "Enter a property name.",
            ParameterSetName = "property"
        )][string]$Property,

        [Parameter(
            Position = 0,
            Mandatory,
            HelpMessage = "Enter an ordered hashtable of conditions and colors.",
            ParameterSetName = "conditions"
        )][System.Collections.Specialized.OrderedDictionary]$Conditions,

        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][PSObject[]]$InputObject
    )

    Begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
        Write-Verbose "Using parameter set $($pscmdlet.ParameterSetName)"
        #save original color
        $saved = $Host.UI.RawUI.ForegroundColor

        Write-Verbose "Original foreground color is $saved"

        if ($PSCmdlet.ParameterSetName -eq 'conditions') {
            #we'll need this later in the Process script block
            #if doing complex processing
            Write-Verbose "Getting hash table enumerator and names"
            $compare = $conditions.GetEnumerator().name
            Write-Verbose $($compare | Out-String)
            #build an If/ElseIf construct on the fly
            #the Here-strings must be left justified
            $If = @"
 if ($($compare[0])) {
  `$host.ui.RawUI.ForegroundColor = '$($conditions.item($($compare[0])))'
 }
"@
            #now add the remaining comparisons as ElseIf
            for ($i = 1; $i -lt $conditions.count; $i++) {
                $If += "elseif ($($compare[$i])) {
         `$host.ui.RawUI.ForegroundColor = '$($conditions.item($($compare[$i])))'
         }
         "
            } #for

            #add the final else
            $if += @"
Else {
`$host.ui.RawUI.ForegroundColor = `$saved
}
"@

            Write-Verbose "Complex comparison:"
            Write-Verbose $If
        } #if complex parameter set

    } #Begin

    Process {

        If ($PSCmdlet.ParameterSetName -eq 'conditions') {
            #Use complex processing
            Invoke-Expression $if
        } #end complex
        else {
            #get property value as a string
            $value = $Inputobject.$Property.ToString()
            Write-Verbose "Testing property value $value"
            if ($PropertyConditions.containsKey($value)) {
                Write-Verbose "Property match"
                $host.ui.RawUI.ForegroundColor = $PropertyConditions.item($value)
            }
            else {
                #use orginal color
                Write-Verbose "No matches found"
                $host.ui.RawUI.ForegroundColor = $saved
            }
        } #simple

        #write the object to the pipeline
        Write-Verbose "Write the object to the pipeline"
        $_
    } #Process

    End {
        Write-Verbose "Restoring original foreground color"
        #set color back
        $host.ui.RawUI.ForegroundColor = $saved
    } #end

} #close function

function Show-ColorTable {
  # aka Show-ColorsANSI
  $colors = [enum]::GetValues([System.ConsoleColor])
  Foreach ($bgcolor in $colors){
      Foreach ($fgcolor in $colors) { Write-Host "$fgcolor|"  -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
      Write-Host " on $bgcolor"
  }
}

## Show-ColorList

function Show-ColorList( ) {
  $colors = [Enum]::GetValues( [ConsoleColor] )
  $max = ($colors | foreach { "$_ ".Length } | Measure-Object -Maximum).Maximum
  foreach( $color in $colors ) {
    Write-Host (" {0,2} {1,$max} " -f [int]$color,$color) -NoNewline
    Write-Host "$color" -Foreground $color
  }
}

## New-ANSIBar

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

###}}} END ANSI / COLOR FUNCTIONS
