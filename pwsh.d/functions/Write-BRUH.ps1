## Write-BRUH  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

Function Write-BRUH {
  <#
  .SYNOPSIS
    Writes customized output to a host.
  .DESCRIPTION
    The Write-BRUH cmdlet customizes output.
    You can specify the color of text by using the ForegroundColor parameter,
    and you can specify the background color by using the BackgroundColor parameter.
    The Separator parameter lets you specify a string to use to separate displayed objects.
    The particular result depends on the program that is hosting Windows PowerShell.
  #>
  [CmdletBinding()]
  Param(
    [Parameter(
      Position = 0,
      ValueFromPipeline = $true,
      ValueFromRemainingArguments = $true
    )]
    [psobject]$Object,
    [switch]$NoNewline,
    [psobject]$Separator,
    [System.ConsoleColor]$ForegroundColor,
    [System.ConsoleColor]$BackgroundColor
  )
  Begin {
    $ObjectStr = $Object.ToString()
    Write-Host -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -NoNewline $NoNewline "BRUH:    $ObjectStr"
  }
}

## Show-ColorTable
