## which  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

Function which(){
  <#
  .SYNOPSIS
    Show what a command is (like 'which' in Linux).

  .DESCRIPTION
    Resolves a command of any type and reports what it actually is:
      * Alias       -> shows what it resolves to, then recurses to follow the
                       chain down to the underlying function/app.
      * Function    -> prints its ScriptBlock definition.
      * Filter      -> prints its ScriptBlock definition.
      * Cmdlet      -> shows the owning module.
      * Application -> shows the executable's path on disk.
    Errors clearly if the name resolves to nothing.

  .PARAMETER Command
    Name of the alias, function, cmdlet, or application to resolve.

  .EXAMPLE
    which ez
    Alias -> follows the chain (e.g. 'ez' -> Reload-Profile) and shows the
    resolved function definition.

  .EXAMPLE
    which Clear-Host
    A function or cmdlet -> prints its definition or owning module.

  .EXAMPLE
    which git
    An application -> prints the full path to git on disk.

  .EXAMPLE
    which doesnotexist
    Prints a clear error since the name resolves to nothing.
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
