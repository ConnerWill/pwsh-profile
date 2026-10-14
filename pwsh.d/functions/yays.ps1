## yays  --  from 23_functions_pkg.ps1 (one-file-per-function layout)

Function yays(){
  [CmdletBinding()]
  Param(
    [Parameter(
      Position = 0,
      ValueFromPipeline = $true,
      ValueFromRemainingArguments = $true,
      Mandatory = $true
    )]
    [string]$SearchQuery
  )
  If ($SearchQuery -eq $null){
    Return
  }
  Else {
    Find-Module -Filter $SearchQuery                              `
      | Select-Object -Property Rank,Name,Description,Properties  `
        | Format-Table -AutoSize -Wrap
  }
}

#####################################################
#   Search for PS Modules In A Less Frustrating Way.
#####################################################
