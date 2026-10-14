## Get-WindowsVersionString  --  from 25_functions_sysinfo.ps1 (one-file-per-function layout)

Function Get-WindowsVersionString {

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
