## Loaded by profile.ps1 pwsh.d loader. Active shell preferences.

###{{{ PREFERENCES

## Default to UTF-8 for file output / redirection operators and any cmdlet
## that has an -Encoding parameter.
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['*:Encoding']        = 'utf8'

## Concise, readable error formatting.
$ErrorView = 'ConciseView'

## Keep more command history.
$MaximumHistoryCount = 8192

## Opt out of PowerShell / .NET CLI telemetry for this session.
$env:POWERSHELL_TELEMETRY_OPTOUT = 1
$env:DOTNET_CLI_TELEMETRY_OPTOUT = 1

###}}} END PREFERENCES
