## which  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

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
