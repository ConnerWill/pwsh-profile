## Reload-Profile  --  re-source the profile in place (no process stacking).

Function Reload-Profile(){
  <#
  .SYNOPSIS
    Reload the profile in the current session (in place).
  .DESCRIPTION
    Dot-sources $PROFILE.CurrentUserAllHosts, which re-runs the pwsh.d loader --
    refreshing functions, aliases, the prompt, PSReadLine handlers, and the
    fragments. Done in place (no new process), so repeated reloads never stack
    shells. NOTE: a function cannot push a re-sourced *variable* into global
    scope, so the profile's user-overridable variables ($EDITOR, $PROMPT_*,
    etc.) are declared $global: in 01_variables.ps1 so they refresh here too.
  .EXAMPLE
    Reload-Profile
    Re-source the profile in the current session.
  .EXAMPLE
    ez
    Reload via the short 'ez' alias (zsh-style).
  .EXAMPLE
    reload
    Reload via the 'reload' alias.
  #>
  [CmdletBinding()]
  [Alias('reload','ez')]
  Param()

  $profilePath = $PROFILE.CurrentUserAllHosts
  if (-not (Test-Path -Path $profilePath)) {
    Write-Warning "Profile not found: $profilePath"
    return
  }

  # Overwrite the command line with a centered "Reloading ..." (zsh 'ez' trick:
  # clear line, up one, clear, carriage return), pause so it's visible, then
  # clear it again before re-sourcing so the reloaded output starts clean.
  [Console]::Write("`e[2K`e[1A`e[2K`r")
  if (Get-Command Write-Centered -ErrorAction Ignore) {
    Write-Centered 'Reloading ...' -Color 46
  } else {
    $g = if ($Colors) { $Colors.Green } else { '' }
    $r = if ($Colors) { $Colors.Reset } else { '' }
    Write-Output "${g}Reloading ...${r}"
  }
  Start-Sleep -Milliseconds 200
  [Console]::Write("`e[1A`r`e[2K")

  . $profilePath
}
