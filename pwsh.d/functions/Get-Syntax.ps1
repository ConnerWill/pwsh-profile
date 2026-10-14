## Get-Syntax  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

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
