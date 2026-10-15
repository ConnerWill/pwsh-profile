## Test-Command  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

Function Test-Command {
  <#
  .SYNOPSIS
    Check whether a command exists (alias, function, cmdlet, or application).
  .DESCRIPTION
    Returns the matching CommandInfo if the name resolves to any command, or
    nothing if it doesn't. Use it in conditionals to gate behavior on a command's
    availability.
  .PARAMETER command
    The command name to look up.
  .EXAMPLE
    Test-Command git
    Returns the git CommandInfo if git is on PATH.
  .EXAMPLE
    if (tcm docker) { 'docker available' }
    Branch on whether a command exists (via the 'tcm' alias).
  .EXAMPLE
    'nope-not-real' | ForEach-Object { if (-not (Test-Command $_)) { "missing: $_" } }
    Report a missing command.
  #>
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
