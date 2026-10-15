## Get-PSWho  --  from 25_functions_sysinfo.ps1 (one-file-per-function layout)

Function Get-PSWho {

    <#
    .SYNOPSIS
      Show a summary of the current user, host, and PowerShell session.
    .DESCRIPTION
      Returns an object (or a formatted string with -AsString) describing who you
      are and where you're running: username, whether the session is elevated,
      computer name, OS and version, PowerShell version/edition/host, execution
      policy, and culture. Works on both Windows and non-Windows platforms.
    .PARAMETER AsString
      Return the summary as a pre-formatted string instead of an object.
    .EXAMPLE
      Get-PSWho
      Show the session summary as an object.
    .EXAMPLE
      pswho -AsString
      Get the summary as formatted text (via the 'pswho' alias).
    .EXAMPLE
      (Get-PSWho).Elevated
      Check just whether the session is running elevated.
    #>
    [CmdletBinding()]
    [OutputType("PSWho","String")]
    [alias("pswho")]

    Param(
        [switch]$AsString
    )

    if ($PSVersionTable.PSEdition -eq "desktop" -OR $PSVersionTable.OS -match "Windows") {

        #get some basic information about the operating system
        $cimos = Get-CimInstance win32_operatingsystem -Property Caption, Version, OSArchitecture
        $os = "$($cimos.Caption) [$($cimos.OSArchitecture)]"
        $osver = $cimos.Version

        #determine the current user so we can test if the user is running in an elevated session
        $current = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$current
        $Elevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        $user = $current.Name
        $computer = $env:COMPUTERNAME
    }
    else {
        #non-Windows values
        $os = $PSVersionTable.OS
        $lsb = lsb_release -d
        $osver = ($lsb -split ":")[1].Trim()
        $elevated =  Test-IsElevated
        $user = [System.Environment]::UserName
        $computer = [System.Environment]::MachineName
    }

    #object properties will be displayed in the order they are listed here
    $who = [pscustomObject]@{
        PSTypeName      = "PSWho"
        User            = $user
        Elevated        = $elevated
        Computername    = $computer
        OperatingSystem = $os
        OSVersion       = $osver
        PSVersion       = $PSVersionTable.PSVersion.ToString()
        Edition         = $PSVersionTable.PSEdition
        PSHost          = $host.Name
        WSMan           = $PSVersionTable.WSManStackVersion.ToString()
        ExecutionPolicy = (Get-ExecutionPolicy)
        Culture         = [System.Globalization.CultureInfo]::CurrentCulture.NativeName
    }

    if ($AsString) {
        ($who | Out-String).trim()
    }
    else {
        $who
    }
} #end Get-PSWho
