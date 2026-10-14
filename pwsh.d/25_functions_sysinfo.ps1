## Loaded by profile.ps1 pwsh.d loader. System/host info functions.
## Moved out of profile.ps1.

###{{{ USER / SYSTEM INFO

Function Get-PSWho {

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

Function Get-WindowsVersion {

    [cmdletbinding()]
    [OutputType("WindowsVersion")]
    [alias('wver')]

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

        $sb = {
            $RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows nt\CurrentVersion\'
            <#
            9/15/2022 JDH
            Revised to use `ysteminfo to retrieve the operating system name and
            if that fails, fall back to using the registry entry.
            The registry entry for Windows 11 typically still shows Windows 10.
            #>
            $regData =  Get-ItemProperty -Path $RegPath
            $tmpCsv = [system.io.path]::GetTempFileName()
            Start-Process systeminfo -ArgumentList "/fo csv" -wait -WindowStyle Hidden -RedirectStandardOutput $tmpCSV
            if ((Get-Item $tmpCSV).Length -gt 0) {
                $osName = Import-CSV $tmpCsv | Select-Object -expand "OS Name"
                Remove-Item -Path $tmpCsv
            }
            else {
                $osName = $regData.ProductName
            }
            $regData | Select-Object -Property @{Name="ProductName";Expression={$osname}}, EditionID, ReleaseID, BuildBranch,
            @{Name = "Build"; Expression = { "$($_.CurrentBuild).$($_.UBR)" } }, DisplayVersion,
            @{Name = "InstalledUTC"; Expression = { ([datetime]"1/1/1601").AddTicks($_.InstallTime) } },
            @{Name = "Computername"; Expression = { $env:computername } }

        } #close scriptblock

        #update PSBoundParameters so it can be splatted to Invoke-Command
        [void]$PSBoundParameters.Add("ScriptBlock", $sb)

    } #begin

    Process {
        if (Test-IsPSWindows) {

            if ($Computername -eq $ENV:Computername) {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing the local host"
                #remove all any passed parameters
                "Credential", "UseSSL", "ThrottleLimit", "Authentication" | ForEach-Object {
                    if ($psboundparameters.ContainsKey($_)) {
                        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Removing parameter $_"
                        [void]($PSBoundparameters.Remove($_))
                    }
                }
            }
            else {
                [void]$PSBoundParameters.add("HideComputername", $True)
            }
            Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Invoking command"

            $PSBoundParameters | Out-String | Write-Verbose
            $results = Invoke-Command @PSBoundParameters | Select-Object -Property * -ExcludeProperty RunspaceID, PS*
            if ($Results) {
                foreach ($item in $results) {

                    [pscustomobject]@{
                        PSTypeName     = "WindowsVersion"
                        ProductName    = $item.ProductName
                        ReleaseVersion = $item.DisplayVersion
                        EditionID      = $item.EditionID
                        ReleaseID      = $item.ReleaseID
                        Build          = $item.Build
                        Branch         = $item.BuildBranch
                        InstalledUTC   = $item.InstalledUTC
                        Computername   = $item.Computername
                    }
                }
            }
        }
        else {
            Write-Warning "This command requires a Windows platform"
        }

    } #process

    End {

        Write-Verbose "[$((Get-Date).TimeOfDay)END    ] Ending $($MyInvocation.Mycommand)"

    } #end
} #close function


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

###}}} END USER / SYSTEM INFO
