## Reload-Profile  --  from 24_functions_system.ps1 (one-file-per-function layout)

Function Reload-Profile(){
  <#
  .SYNOPSIS
    Reload the shell by starting a fresh PowerShell session.
  .DESCRIPTION
    Dot-sourcing the profile from inside a function cannot push the profile's
    variables (e.g. $EDITOR, $PROMPT_USERNAME, colors) into the global scope, so
    an in-place reload silently drops them. Instead we start a brand-new
    interactive pwsh (like 'exec zsh'/'ez' in zsh) and exit the current one when
    it returns, guaranteeing every change in profile.ps1 / powershell-config.ps1
    takes effect.
  .EXAMPLE
    Reload-Profile
  #>
  [CmdletBinding()]
  [Alias('reload','ez')]
  Param()

  $pwshPath = (Get-Process -Id $PID).Path
  if (-not $pwshPath) { $pwshPath = 'pwsh' }

  # Clear the current line, move up one, clear it, return to column 0 -- so the
  # centered "Reloading ..." overwrites the command line (same trick as the zsh
  # 'ez'). Then print the message bold-green and centered.
  [Console]::Write("`e[2K`e[1A`e[2K`r")
  if (Get-Command Write-Centered -ErrorAction Ignore) {
    [Console]::Write("`e[1m")
    Write-Centered 'Reloading ...' -Color 46 -NoNewline
    [Console]::Write("`e[0m`e[1A`r")
  }
  else {
    Write-Host "Reloading shell..." -ForegroundColor Green
  }

  # Start a fresh interactive session in the same window, then exit this one
  # so it behaves like a shell replacement.
  & $pwshPath -NoLogo
  exit
}
