## Test-Command  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

Function Test-Command {
  [CmdletBinding()]
  Param (
    [Parameter(
      Mandatory = $true,
      Position = 0
    )]
    [string] $command
  )
  Get-Command -Name $command -ErrorAction Ignore
}; Set-Alias -Name tcm -Value Test-Command
