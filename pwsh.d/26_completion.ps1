## Loaded by profile.ps1 pwsh.d loader. Tab-completion integrations.

###{{{ COMPLETION

# Chocolatey tab-completion. See https://ch0.co/tab-completion
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

## Command-name completion for our command-introspection helpers.
## These functions take a command (alias/function/cmdlet/application) as their
## argument; tab-complete it from the live command table, like built-in cmdlets.
$__CommandNameCompleter = {
  param($wordToComplete, $commandAst, $cursorPosition)

  # On script functions, $wordToComplete is sometimes populated with the command
  # name itself rather than the argument being typed. Derive the real partial
  # word from the AST: the command element whose extent sits at the cursor.
  $word = $wordToComplete
  $cmdName = $commandAst.CommandElements[0].ToString()
  if ([string]::IsNullOrEmpty($word) -or $word -eq $cmdName) {
    $word = ''
    foreach ($el in $commandAst.CommandElements) {
      if ($el -eq $commandAst.CommandElements[0]) { continue }      # skip the command name
      if ($el.ToString().StartsWith('-')) { continue }              # skip parameter switches
      if ($el.Extent.EndOffset -le $cursorPosition) {
        $word = $el.ToString().Trim([char]0x27, [char]0x22)         # strip ' and "
      }
    }
  }

  Get-Command -Name "$word*" -ErrorAction Ignore |
    Sort-Object Name -Unique |
    Select-Object -First 50 |
    ForEach-Object {
      [System.Management.Automation.CompletionResult]::new(
        $_.Name,
        $_.Name,
        'ParameterValue',
        ('{0} [{1}]' -f $_.Name, $_.CommandType)
      )
    }
}

## Map: function -> the parameter that takes a command name. Aliases resolve to
## the same function, so registering the function name covers its aliases too.
$__CommandNameTargets = @{
  'which'          = 'Command'
  'Get-CommandInfo' = 'Name'
  'Get-Syntax'     = 'Name'
  'Get-CmdletAlias' = 'cmdletname'
  'Test-Command'   = 'command'
}
foreach ($fn in $__CommandNameTargets.Keys) {
  if (Get-Command $fn -ErrorAction Ignore) {
    Register-ArgumentCompleter -CommandName $fn `
      -ParameterName $__CommandNameTargets[$fn] `
      -ScriptBlock $__CommandNameCompleter
  }
}
Remove-Variable __CommandNameCompleter, __CommandNameTargets -ErrorAction Ignore

###}}} END COMPLETION
