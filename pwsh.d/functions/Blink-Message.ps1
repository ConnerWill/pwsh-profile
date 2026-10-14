## Blink-Message  --  from 22_functions_ansi.ps1 (one-file-per-function layout)

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
