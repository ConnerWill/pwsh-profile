## Get-WindowsVersionString  --  from 25_functions_sysinfo.ps1 (one-file-per-function layout)

Function Get-WindowsVersionString {

    <#
    .SYNOPSIS
      Get a one-line Windows version string for one or more computers.
    .DESCRIPTION
      A thin wrapper over Get-WindowsVersion that formats the result as a single
      readable line per computer, e.g. "PC01 Windows 11 Pro Version Enterprise
      (OS Build 22631.4169)". Accepts the same remoting parameters.
    .PARAMETER Computername
      One or more computers to query (default: local machine). Pipeline-aware.
    .PARAMETER Credential
      Credential to use for remote queries.
    .PARAMETER UseSSL
      Use SSL for the remote WSMan connection.
    .PARAMETER ThrottleLimit
      Max concurrent remote connections.
    .PARAMETER Authentication
      WSMan authentication mechanism (Default, Kerberos, Negotiate, ...).
    .EXAMPLE
      Get-WindowsVersionString
      One-line version summary for the local machine.
    .EXAMPLE
      Get-WindowsVersionString -Computername server01 -Credential (Get-Credential)
      Version string for a remote host.
    .EXAMPLE
      'web01','web02' | Get-WindowsVersionString
      One line per host from the pipeline.
    #>
    [cmdletbinding()]
    [OutputType("system.string")]

    Param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Computername = $env:COMPUTERNAME,
        [PSCredential]$Credential,
        [switch]$UseSSL,
        [Int32]$ThrottleLimit,
        [ValidateSet('Default', 'Basic', 'Credssp', 'Digest', 'Kerberos', 'Negotiate', 'NegotiateWithImplicitCredential')]
        [ValidateNotNullorEmpty()]
        [string]$Authentication = "default"
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.Mycommand)"
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Calling Get-WindowsVersion"
        $results = Get-WindowsVersion @PSBoundParameters

        #write a version string for each computer
        foreach ($result in $results) {
            "{3} {0} Version {1} (OS Build {2})" -f $result.ProductName, $result.EditionID, $result.build, $result.computername
        }

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.Mycommand)"
    } #end
}
