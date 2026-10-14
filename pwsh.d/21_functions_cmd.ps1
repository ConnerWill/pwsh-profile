## Loaded by profile.ps1 pwsh.d loader. Split from the old 03/05_functions.ps1.

###{{{ COMMAND / INTROSPECTION FUNCTIONS

Function which(){
  <#
  .SYNOPSIS
    Show what a command is (like 'which' in linux).

  .DESCRIPTION
    Resolves a command of any type:
      * Alias       -> shows what it resolves to (following the chain).
      * Function    -> shows its ScriptBlock definition.
      * Cmdlet      -> shows the owning module.
      * Application -> shows the path on disk.

  .EXAMPLE
	  which ez          # alias -> Reload-Profile

  .EXAMPLE
	  which Clear-Host  # function/cmdlet

  .EXAMPLE
	  which git         # application path
  #>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $true, Position = 0)][string]$Command
  )

  $cmd = Get-Command -Name $Command -ErrorAction Ignore
  if (-not $cmd) {
    Write-Error "'$Command' not found as an alias, function, cmdlet, or application."
    return
  }

  switch ($cmd.CommandType) {
    'Alias' {
      $resolved = $cmd.ResolvedCommandName
      Write-Output "$Command is an alias for '$resolved'"
      # Recurse so you also see the underlying function/app definition.
      if ($resolved) { which $resolved }
    }
    'Function'    { $cmd.ScriptBlock }
    'Filter'      { $cmd.ScriptBlock }
    'Cmdlet'      { Write-Output "$Command is a cmdlet in module '$($cmd.ModuleName)'" }
    'Application' { $cmd.Source }
    default       { $cmd | Format-List -Property Name, CommandType, Source, Version }
  }
}

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

Function Get-Syntax {
  <#
  .SYNOPSIS
    Get the syntax for a command.
  .DESCRIPTION
    Get the possible syntax for a command.
    Wrapper function for Get-Command -Syntax.
  .EXAMPLE
	  Get-Syntax -Name Get-Help
  #>
  [CmdletBinding()]
  [Alias('synt', 'syntax')]
  Param (
    # The name of a command.
    [Parameter(
      Mandatory,
      Position = 1,
      ValueFromPipelineByPropertyName,
      ParameterSetName = 'ByName'
    )]
    [String]$Name,
    # A CommandInfo object.
    [Parameter(
      Mandatory,
      ValueFromPipeline,
      ParameterSetName = 'FromCommandInfo'
    )]
    [System.Management.Automation.CommandInfo]$CommandInfo,
    # Write syntax in the short format used by Get-Command.
    [Switch]$Short
  )
  Begin {
    $commonParams = @(
      [System.Management.Automation.Internal.CommonParameters].GetProperties().Name
      [System.Management.Automation.Internal.ShouldProcessParameters].GetProperties().Name
      [System.Management.Automation.Internal.TransactionParameters].GetProperties().Name
    )
  }
  Process {
    $CommandInfo = Get-CommandInfo @psboundparameters
    ForEach ($parameterSet in $CommandInfo.ParameterSets) {
      If ($Short) { "`n{0} {1}" -f $CommandInfo.Name, $parameterSet }
      Else {
        $stringBuilder = [System.Text.StringBuilder]::new().AppendFormat('{0} ', $commandInfo.Name)
        $null = foreach ($parameter in $parameterSet.Parameters) {
          If ($parameter.Name -notin $commonParams) {
            If (-not $parameter.IsMandatory) {
              $stringBuilder.Append('[')
            }
            If ($parameter.Position -gt [Int32]::MinValue) {
              $stringBuilder.Append('[')
            }
            $stringBuilder.AppendFormat('-{0}', $parameter.Name)
            If ($parameter.Position -gt [Int32]::MinValue) {
              $stringBuilder.Append(']')
            }
            If ($parameter.ParameterType -ne [Switch]) {
              $stringBuilder.AppendFormat(' <{0}>', $parameter.ParameterType.Name)
            }
            If (-not $parameter.IsMandatory) {
              $stringBuilder.Append(']')
            }
            $stringBuilder.AppendLine().Append(' ' * ($commandInfo.Name.Length + 1))
          }
        }
        $stringBuilder.AppendLine().ToString()
      }
    }
  }
}; Get-Item -Path function:\help -EA SilentlyContinue | Remove-Item; Set-Alias -Name help -Value Get-Syntax

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

function Encode-Command($command){
  $bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
  $encodedCommand = [Convert]::ToBase64String($bytes)
  echo "pwsh -NoLogo -NoProfile -encodedcommand $encodedCommand" | Set-Clipboard
  Write-Output "pwsh -NoLogo -NoProfile -encodedcommand $encodedCommand"
}

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

###}}} END COMMAND / INTROSPECTION FUNCTIONS
