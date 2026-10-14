## Loaded by profile.ps1 pwsh.d loader. Split from the old 03/05_functions.ps1.

###{{{ SYSTEM / ADMIN FUNCTIONS

Function Start_PSTranscript(){
  if (-not $PS_TRANSCRIPT_ENABLED){ return }

  # Ensure the directory exists (no recursion: just create it, then continue).
  if (-not (Test-Path -Path $PS_TRANSCRIPT_DIR)){
    try { New-Item -Path $PS_TRANSCRIPT_DIR -ItemType Directory -Force -ErrorAction Stop | Out-Null }
    catch { Write-Warning "Transcript dir unavailable: $PS_TRANSCRIPT_DIR"; return }
  }

  # Prune old transcripts so the directory doesn't grow without bound.
  $max = if ($PS_TRANSCRIPT_MAX -is [int]) { $PS_TRANSCRIPT_MAX } else { 50 }
  if ($max -gt 0){
    Get-ChildItem -Path $PS_TRANSCRIPT_DIR -Filter 'PowerShell_transcript.*.log' -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -Skip $max |
      Remove-Item -Force -ErrorAction SilentlyContinue
  }

  # If a transcript is already running (e.g. after Reload-Profile), stop it first
  # so we don't stack transcripts. Stop-Transcript throws when none is active, so
  # swallow that case.
  try { Stop-Transcript | Out-Null } catch { }

  $CurrentDate = Get-Date -Format 'yyyyMMddHHmmss'
  Start-Transcript -Path "$PS_TRANSCRIPT_DIR\PowerShell_transcript.$CurrentDate.log" >$null 2>&1
}; Start_PSTranscript

## LS functions

Function ssh-local(){
  <#
  .SYNOPSIS
    SSH to a (local) host over a given port.
  .DESCRIPTION
    Generic helper with no hardcoded identity. Set personal defaults by
    wrapping or re-parameterizing this in powershell-config.ps1.
  .EXAMPLE
    ssh-local -User me -Hostname localhost -Port 2222
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory, Position = 0)][string]$User,
    [Parameter(Position = 1)][string]$Hostname = "localhost",
    [Parameter(Position = 2)][int]$Port = 22
  )
  $userHost = "$User@$Hostname"
  if ($PSVersionTable.PSVersion.Major -eq 7){ Write-Output "`e[0;38;5;87mConnecting to '`e[0;1;38;5;201m$userHost`e[0;38;5;87m' over SSH (port $Port)`e[0m" }
  else { Write-Output "Connecting to $userHost over SSH (port $Port)" }
  ssh -p $Port $userHost
}

## Admin Check
#if (!(Verify-Elevated)) {
#  $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
#  $newProcess.Arguments = $myInvocation.MyCommand.Definition;
#  $newProcess.Verb = "runas";
#  [System.Diagnostics.Process]::Start($newProcess);
#
#  exit
#}

Function Update-Windows(){
	$SepLine = "===================================="
	clear
	Write-Host "Downloading Windows Update ..." -ForegroundColor Cyan
	Write-Host $SepLine -ForegroundColor Yellow
	Get-WindowsUpdate -Download -AcceptAll -IgnoreReboot -WindowsUpdate -Verbose
	Write-Host $SepLine -ForegroundColor Yellow
	Write-Host "Installing Windows Update ..." -ForegroundColor Cyan
	Write-Host $SepLine -ForegroundColor Yellow
	Install-WindowsUpdate -AcceptAll -Install -IgnoreReboot -WindowsUpdate -Verbose
	Write-Host $SepLine -ForegroundColor Yellow
	Write-Host "DONE" -BackgroundColor Green -ForegroundColor White
}

Function Get-WiFiPasswords(){
#\ function Get-WiFiPasswords(){(netsh wlan show profiles) | Select-String "\:(.+)$" | %{$name=$_.Matches.Groups[1].Value.Trim(); $_} | %{(netsh wlan show profile name="$name" key=clear)}  | Select-String "Key Content\W+\:(.+)$" | %{$pass=$_.Matches.Groups[1].Value.Trim(); $_} | %{[PSCustomObject]@{ PROFILE_NAME=$name;PASSWORD=$pass }} | Format-Table -AutoSize}
    (netsh wlan show profiles) | Select-String "\:(.+)$" | ForEach-Object{
      $name=$_.Matches.Groups[1].Value.Trim(); $_
    } | ForEach-Object{
          (netsh wlan show profile name="$name" key=clear)
        } | Select-String "Key Content\W+\:(.+)$" | ForEach-Object{
                $pass=$_.Matches.Groups[1].Value.Trim(); $_
              } | ForEach-Object{
                    [PSCustomObject]@{
                      PROFILE_NAME=$name;PASSWORD=$pass
                    }
                  } | Format-Table -AutoSize
}

###}}} END FUNCTIONS

Function Reload-Profile(){
  <#
  .SYNOPSIS
    Reload the PowerShell profile in the current session.
  .DESCRIPTION
    Re-sources the CurrentUserAllHosts profile (profile.ps1), which in turn
    re-runs the pwsh.d loader. Handy for testing profile changes without
    opening a new shell.
  .EXAMPLE
    Reload-Profile
  #>
  [CmdletBinding()]
  [Alias('reload','src','ez')]
  Param()
  $profilePath = $PROFILE.CurrentUserAllHosts
  if (Test-Path -Path $profilePath) {
    Write-Host "Reloading profile: $profilePath" -ForegroundColor Cyan
    . $profilePath
  }
  else {
    Write-Warning "Profile not found: $profilePath"
  }
}

###}}} END SYSTEM / ADMIN FUNCTIONS
