## Get-CommandInfo  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

Function Get-CommandInfo {
  <#
  .SYNOPSIS
      Get information for a command.
  .DESCRIPTION
      Get information for a command. Like 'which' in linux.
  .EXAMPLE
	  Get-CommandInfo -Name ssh
      Application     ssh.exe		8.1.0.1    C:\Windows\System32\OpenSSH\ssh.exe
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
