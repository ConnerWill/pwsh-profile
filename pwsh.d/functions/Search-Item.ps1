## Search-Item  --  from 20_functions_fs.ps1 (one-file-per-function layout)

Function Search-Item {
  [cmdletbinding()]
  param(
      [parameter(position = 0)]
      [alias("pattern")]
      [string]$filter = "*.*",
      [parameter(
        position = 1,
        valuefrompipeline = $true,
        valuefrompipelinebypropertyname = $true
      )]
      [alias("fullname")]
      [alias("pspath")]
      [string]$path = $pwd
  )
  Process {
    Write-Host "Searching in $path"
    Get-ChildItem -Path $path -Recurse -Filter $filter -EA SilentlyContinue | ForEach-Object {
      Write-Output $_.FullName
    }
  }
}; Set-Alias -Name search -Value Search-Item
