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

  # Jump up one line and overwrite it with a centered "Reloading ...", matching
  # the zsh 'ez' trick:  clear line, cursor up one, clear line, carriage return.
  # (Scrollback is preserved; only the previous line is overwritten.)
  [Console]::Write("`e[2K`e[1A`e[2K`r")
  if (Get-Command Write-Centered -ErrorAction Ignore) {
    Write-Centered 'Reloading ...' -Color 46
  }
  else {
    Write-Host 'Reloading ...' -ForegroundColor Green
  }

  # Move the cursor back up onto the "Reloading ..." line AND clear it, so the
  # fresh shell's output starts on a blank line with no leftover text (the
  # "Reloading ..." line is wider than the new output, so without the clear its
  # tail would survive).
  [Console]::Write("`e[1A`r`e[2K")

  # Start a fresh interactive session in the same window, then exit this one
  # so it behaves like a shell replacement.
  & $pwshPath -NoLogo
  exit
}
