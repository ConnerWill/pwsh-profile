## Package / module helpers.
## Consolidates the old Search-Modules / Search-Script / Search-Choco / yays /
## Instort-Module functions into two consistent, parameterized commands:
##   Find-Package     - search PowerShell Gallery modules/scripts or Chocolatey
##   Install-PSModule - install + import a module (and show its commands)

Function Find-Package {
  <#
  .SYNOPSIS
    Search for packages from the PowerShell Gallery or Chocolatey.
  .DESCRIPTION
    One search command for all sources. Pass the query as an argument (no
    interactive prompt, no screen-clearing) so it composes in pipelines.
  .PARAMETER Query
    Text to search for.
  .PARAMETER Source
    Where to search: Module (default) / Script (PowerShell Gallery) or Choco.
  .EXAMPLE
    Find-Package posh
  .EXAMPLE
    Find-Package pester -Source Script
  .EXAMPLE
    Find-Package vlc -Source Choco
  #>
  [CmdletBinding()]
  [Alias('fpkg', 'Search-Modules', 'Search-Script', 'Search-Choco')]
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Query,

    [ValidateSet('Module', 'Script', 'Choco')]
    [string]$Source = 'Module'
  )

  switch ($Source) {
    'Module' {
      Find-Module -Name "*$Query*" -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object Name, Version, Description |
        Format-Table -AutoSize -Wrap
    }
    'Script' {
      Find-Script -Name "*$Query*" -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object Name, Version, Description |
        Format-Table -AutoSize -Wrap
    }
    'Choco' {
      if (-not (Get-Command choco -ErrorAction Ignore)) {
        Write-Warning 'Chocolatey (choco) is not installed.'
        return
      }
      choco search $Query --order-by=Popularity --detailed --not-broken --page-size=25
    }
  }
}

Function Install-PSModule {
  <#
  .SYNOPSIS
    Install a PowerShell module (CurrentUser) and import it.
  .DESCRIPTION
    Replaces the old 'Instort-Module'. Takes the name as a parameter instead of
    prompting, installs for the current user, imports it, and lists its commands.
  .EXAMPLE
    Install-PSModule posh-git
  .EXAMPLE
    'Pester','PSReadLine' | Install-PSModule
  #>
  [CmdletBinding()]
  [Alias('ipsmod', 'Instort-Module')]
  param(
    [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
    [string[]]$Name
  )

  process {
    $cInfo = if ($Colors) { $Colors.Yellow } else { '' }
    $cOk   = if ($Colors) { $Colors.Green }  else { '' }
    $cRst  = if ($Colors) { $Colors.Reset }  else { '' }
    foreach ($m in $Name) {
      try {
        Write-Output "${cInfo}Installing module: $m${cRst}"
        Install-Module -Name $m -Scope CurrentUser -Force -AcceptLicense -ErrorAction Stop
        Import-Module -Name $m -ErrorAction Stop
        Write-Output "${cOk}Installed + imported: $m${cRst}"
        Get-Command -Module $m -ErrorAction SilentlyContinue
      }
      catch {
        Write-Error "Failed to install '$m': $($_.Exception.Message)"
      }
    }
  }
}
