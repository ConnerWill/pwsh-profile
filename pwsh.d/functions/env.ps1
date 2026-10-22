## env  --  list environment variables (like 'env' / 'printenv' in Linux).

Function env {
  <#
  .SYNOPSIS
    List environment variables (like 'env' / 'printenv').
  .DESCRIPTION
    Prints environment variables as NAME=VALUE lines, sorted by name. With a
    -Name/pattern argument, shows only variables whose name matches (wildcards
    supported, case-insensitive) -- and if the pattern matches exactly one
    variable, prints just its value (like 'printenv PATH'). Use -Raw to get
    objects instead of text.
  .PARAMETER Name
    Optional name or wildcard pattern to filter by (e.g. 'PATH', 'PS*').
  .PARAMETER Raw
    Emit [pscustomobject] Name/Value pairs instead of NAME=VALUE text.
  .EXAMPLE
    env
    List every environment variable, sorted.
  .EXAMPLE
    env PATH
    Print just the value of PATH.
  .EXAMPLE
    env 'PS*'
    Show all variables whose name starts with PS.
  .EXAMPLE
    env -Raw | Where-Object Value -match 'python'
    Filter variables by value using objects.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [string]$Name = '*',
    [switch]$Raw
  )

  $vars = Get-ChildItem Env: | Sort-Object Name |
    Where-Object { $_.Name -like $Name }

  if ($Raw) {
    return $vars | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Value = $_.Value } }
  }

  # Exact single match -> print just the value (printenv-style).
  if ($Name -ne '*' -and $Name -notmatch '[\*\?]' -and @($vars).Count -eq 1) {
    return $vars[0].Value
  }

  $vars | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value }
}
