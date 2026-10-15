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

  # Clear the screen and show a centered "Reloading ..." for a clean handoff.
  # (The old cursor-up overwrite trick doesn't help here: unlike zsh's in-place
  # `exec zsh`, we spawn a fresh pwsh whose own banner repaints the screen, so
  # we just clear first and let the new shell start clean.)
  Clear-Host
  if (Get-Command Write-Centered -ErrorAction Ignore) {
    Write-Centered 'Reloading ...' -Color 46
  }
  else {
    Write-Host 'Reloading ...' -ForegroundColor Green
  }
  Start-Sleep -Milliseconds 300

  # Start a fresh interactive session in the same window, then exit this one
  # so it behaves like a shell replacement.
  & $pwshPath -NoLogo
  exit
}
