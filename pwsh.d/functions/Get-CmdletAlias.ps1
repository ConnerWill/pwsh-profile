## Get-CmdletAlias  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

Function Get-CmdletAlias ($cmdletname) {
  <#
  .SYNOPSIS
    List the aliases that point at a given command.

  .DESCRIPTION
    Shows every alias whose definition matches the supplied command name, as a
    table of Definition -> Name. Handy for discovering the short names a cmdlet
    or function can be invoked by. The -cmdletname value is matched with -like,
    so wildcards work. Registered under the 'aliases' alias.

  .PARAMETER cmdletname
    The command name (or wildcard pattern) to find aliases for, e.g.
    'Get-ChildItem' or 'Get-*'.

  .EXAMPLE
    Get-CmdletAlias Get-ChildItem
    List the aliases for Get-ChildItem (e.g. gci, ls, dir).

  .EXAMPLE
    aliases Get-ChildItem
    Same thing via the 'aliases' alias.

  .EXAMPLE
    Get-CmdletAlias 'Set-*'
    Wildcard: list aliases for every Set-* command.
  #>
  Get-Alias | Where-Object -FilterScript {$_.Definition -like "$cmdletname"} | Format-Table -Property Definition, Name -AutoSize
}; Set-Alias -Name aliases -Value Get-CmdletAlias

## Touch
