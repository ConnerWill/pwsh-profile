## Search-Item  --  from 20_functions_fs.ps1 (one-file-per-function layout)

Function Search-Item {
  <#
  .SYNOPSIS
    Recursively search for files by name/wildcard from a starting directory.
  .DESCRIPTION
    Walks a directory tree and returns the full paths of files matching a
    wildcard filter. This is a filename search (like 'find -name'); to search
    file *contents* use grep instead.
  .PARAMETER filter
    Wildcard filename pattern to match (default '*.*'). Alias: -pattern.
  .PARAMETER path
    Directory to start from (default: current directory). Accepts pipeline input.
  .EXAMPLE
    Search-Item *.ps1
    Find all .ps1 files under the current directory.
  .EXAMPLE
    search *.log C:\Temp
    Find log files under C:\Temp (via the 'search' alias).
  .EXAMPLE
    Get-Item ~\Documents | Search-Item -filter *.md
    Pipe a starting directory in.
  #>
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
    Write-Verbose "Searching in $path"
    Get-ChildItem -Path $path -Recurse -Filter $filter -EA SilentlyContinue | ForEach-Object {
      Write-Output $_.FullName
    }
  }
}; Set-Alias -Name search -Value Search-Item
