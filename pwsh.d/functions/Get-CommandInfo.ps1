## Get-CommandInfo  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

Function Get-CommandInfo {
  <#
  .SYNOPSIS
      Resolve and return the CommandInfo object for a command.
  .DESCRIPTION
      Returns the CommandInfo for a command (similar in spirit to 'which' in
      Linux, but returns the object rather than text). Aliases are resolved to
      their underlying command. Optionally searches inside a module's private
      scope. Accepts either a name or an existing CommandInfo object.
  .PARAMETER Name
      Name of the command to resolve (parameter set 'ByName').
  .PARAMETER CommandInfo
      An existing CommandInfo object to normalize/resolve (parameter set
      'FromCommandInfo').
  .PARAMETER ModuleName
      If supplied, the command is looked up inside that module's private /
      internal scope (imports the module if needed).
  .PARAMETER EaterOfArgs
      Internal: swallows any extra supplied arguments so callers can splat
      freely. Not intended for direct use.
  .EXAMPLE
      Get-CommandInfo -Name ssh
      Returns the CommandInfo (Application) for ssh, including its path/version.
  .EXAMPLE
      Get-CommandInfo Get-ChildItem
      Resolve a cmdlet by positional name.
  .EXAMPLE
      Get-CommandInfo -Name Format-Hex -ModuleName Microsoft.PowerShell.Utility
      Resolve a command within a specific module's scope.
  #>
  [CmdletBinding()]
  Param (
    # The name of a command.
    [Parameter(Mandatory, ParameterSetName = 'ByName')][String]$Name,
    # A CommandInfo object.
    [Parameter(Mandatory, ParameterSetName = 'FromCommandInfo')]
    [System.Management.Automation.CommandInfo]$CommandInfo,
    # If a module name is specified the private / internal scope of the module will be searched.
    [String]$ModuleName,
    # Claims and discards any other supplied arguments.
    [Parameter(ValueFromRemainingArguments, DontShow)]$EaterOfArgs
  )
  If ($Name) {
    If ($ModuleName) {
      Try {
        If (-not ($moduleInfo = Get-Module $ModuleName)) {
          $moduleInfo = Import-Module $ModuleName -Global -PassThru
        }
        $CommandInfo = & $moduleInfo ([ScriptBlock]::Create('Get-Command {0}' -f $Name))
      }
      Catch {
        $pscmdlet.ThrowTerminatingError($_)
      }
    }
    Else {
      $CommandInfo = Get-Command -Name $Name
    }
  }
  If ($CommandInfo -is [System.Management.Automation.AliasInfo]) {
    $CommandInfo = $CommandInfo.ResolvedCommand
  }
  Return $CommandInfo
}

## https://raw.githubusercontent.com/brettmillerb/Toolbox/master/Public/Get-Syntax.ps1
