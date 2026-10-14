## ssh-local  --  from 24_functions_system.ps1 (one-file-per-function layout)

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
