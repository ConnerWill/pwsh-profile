## Get-CmdletAlias  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

Function Get-CmdletAlias ($cmdletname) {
  <#
  .SYNOPSIS
    Displays the aliases of a cmdlet

  .DESCRIPTION
    Displays the aliases of a cmdlet

  .EXAMPLE
	  Get-CmdletAlias Get-ChildItem

  .EXAMPLE
	  Aliases Get-ChildItem
  #>
  Get-Alias | Where-Object -FilterScript {$_.Definition -like "$cmdletname"} | Format-Table -Property Definition, Name -AutoSize
}; Set-Alias -Name aliases -Value Get-CmdletAlias

## Touch
