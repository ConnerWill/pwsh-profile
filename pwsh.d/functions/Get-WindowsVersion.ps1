## Get-WindowsVersion  --  from 25_functions_sysinfo.ps1 (one-file-per-function layout)

Function Get-WindowsVersion {

    <#
    .SYNOPSIS
      Get detailed Windows version information for one or more computers.
    .DESCRIPTION
      Returns a rich object (ProductName, ReleaseVersion, EditionID, Build,
      branch, install date, etc.) by combining 'systeminfo' output with the
      registry, which corrects the Windows 11 "still says Windows 10" registry
      quirk. Can target remote machines via Invoke-Command with credential,
      SSL, and authentication options. Windows-only.
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
      Get-WindowsVersion
      Get version details for the local machine.
    .EXAMPLE
      wver -Computername server01 -Credential (Get-Credential)
      Query a remote host with explicit credentials (via the 'wver' alias).
    .EXAMPLE
      'web01','web02' | Get-WindowsVersion | Format-Table Computername, ProductName, Build
      Query several hosts from the pipeline.
    #>
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
