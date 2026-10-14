## touch  --  from 20_functions_fs.ps1 (one-file-per-function layout)

Function touch(){
  <#
  .SYNOPSIS
    Create a new empty file.

  .DESCRIPTION
    Create a new empty file. Like 'touch' in linux.

  .EXAMPLE
	  touch new_file.txt

  .EXAMPLE
	  touch $env:USERPROFILE\Documents\new_file.txt

  .EXAMPLE
	  touch -Name $env:USERPROFILE\Documents\new_file.txt

  .EXAMPLE
	  touch -Path $env:USERPROFILE\Desktop -Name new_file.txt
  #>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $true,Position = 0)][string]$Name,
    [Parameter(Mandatory = $false)][string]$Path = $PWD
  )
  Try { New-Item -ItemType "file" -Path $Path -Name $Name | Out-Null }
  Catch { Write-Error "Failed to create file" }
}

## SSH Functions
