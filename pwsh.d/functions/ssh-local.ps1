## ssh-local  --  from 24_functions_system.ps1 (one-file-per-function layout)

Function ssh-local(){
  <#
  .SYNOPSIS
    SSH to a host over a given port (defaults geared toward a local VM).
  .DESCRIPTION
    A thin, identity-free wrapper around 'ssh' that builds the user@host target
    and prints a colored "Connecting ..." banner (on PS 7) before invoking ssh.
    No credentials or hostnames are hardcoded. Set personal shortcuts by wrapping
    it in powershell-config.ps1, e.g.:
      function ssh-local-vm { ssh-local -User me -Hostname localhost -Port 2222 }
  .PARAMETER User
    Username to connect as (required). Combined with -Hostname as user@host.
  .PARAMETER Hostname
    Target host name or IP (default 'localhost').
  .PARAMETER Port
    TCP port for the SSH connection (default 22).
  .EXAMPLE
    ssh-local -User me -Hostname localhost -Port 2222
    Connect to a local VM forwarded on port 2222.
  .EXAMPLE
    ssh-local admin 192.168.1.10
    Positional: user 'admin' on host 192.168.1.10, default port 22.
  .EXAMPLE
    ssh-local me
    Connect to me@localhost on port 22 (both defaults).
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
