## Loaded by profile.ps1 pwsh.d loader. Split from the old 03/05_functions.ps1.

###{{{ FILESYSTEM & NAVIGATION FUNCTIONS

Function Motd-AsciiArt(){
  If ($ShowStartupArt){
    . $env:USERPROFILE\Documents\Powershell\ascii-art.ps1
    If ($PSVersionTable.PSVersion.Major -eq 7){
      Write-Output "`e[0;38;5;196m$GRIMREAPER`e[0m"
      Write-Output "`e[0;1;38;5;15m=============================================`e[0m"
    }
    Else {
      "$GRIMREAPER"
    }
  }
}

## Logging function

Function l(){
  try { Get-ChildItemColorFormatWide | Select-Object -Property Name }
  catch { Get-ChildItem | Select-Object -Property Name }
}

Function ll(){
  try { Get-ChildItemColor }
  catch { Get-ChildItem | Select-Object * | Format-Table -AutoSize -Wrap }
}


## 'sl' is a built-in alias for Set-Location. Remove it (if present) so our
## own sl function can take over. Guarded so re-sourcing (reload) doesn't throw.
if (Get-Alias -Name sl -ErrorAction Ignore) { Remove-Alias -Name sl -Force }

Function sl(){
  try { Get-ChildItemColor }
  catch { Get-ChildItem }
}

## CD functions

Function cdp(){
  cd $(Split-Path -Path $PROFILE -Parent)
}


## which

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

Function e(){
  [CmdletBinding()]
  Param([Parameter(Position = 0,ValueFromPipeline = $True,ValueFromRemainingArguments = $True,Mandatory = $False)]
  [string]$Path)

  # Resolve the configured editor; fail with a clear message if it's missing.
  if (-not (Get-Command $EDITOR -ErrorAction Ignore)) {
    Write-Error "Editor '$EDITOR' not found on PATH. Set `$EDITOR in profile.ps1."
    return
  }
  # No path given -> just open the editor (don't pass $PWD, which would make the
  # editor try to open every file in the current directory).
  if ([string]::IsNullOrWhiteSpace($Path)) {
    & $EDITOR
  }
  else {
    & $EDITOR $Path
  }
}

###}}} END FILESYSTEM & NAVIGATION FUNCTIONS
