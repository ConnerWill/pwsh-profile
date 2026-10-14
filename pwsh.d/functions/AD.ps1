## Active Directory helpers.
## These require the ActiveDirectory module (RSAT). The cmdlets auto-load it on
## first use; each function try/catches so a missing module or failed lookup
## reports a clear error instead of throwing noise into the session.
##
## Run as a specific user / against a specific DC:
##   Every function accepts -Credential and -Server, passed through to the AD
##   cmdlets. You do NOT need to be logged in as that user -- the query runs
##   under the supplied credential. Example:
##     $cred = Get-Credential CONTOSO\admin
##     Get-AdUserInfo jdoe -Credential $cred -Server dc01.contoso.com

Function Get-UserAdGroupMembership {
  <#
  .SYNOPSIS
    List the AD groups a user (or users) belongs to.
  .EXAMPLE
    Get-UserAdGroupMembership
  .EXAMPLE
    Get-UserAdGroupMembership jdoe, asmith
  .EXAMPLE
    Get-UserAdGroupMembership jdoe -Credential (Get-Credential) -Server dc01
  #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [string[]]$Identity = @($env:USERNAME),

    [pscredential]$Credential,
    [string]$Server
  )

  # Build splat for the optional -Credential / -Server passthrough.
  $common = @{}
  if ($Credential) { $common.Credential = $Credential }
  if ($Server)     { $common.Server     = $Server }

  foreach ($User in $Identity) {
    try {
      Get-ADPrincipalGroupMembership -Identity $User @common -ErrorAction Stop |
        Sort-Object Name |
        Select-Object @{
          Name       = 'User'
          Expression = { $User }
        }, Name, GroupCategory, GroupScope
    }
    catch {
      Write-Error "Failed to retrieve groups for '$User': $_"
    }
  }
}

Function Get-AdUserInfo {
  <#
  .SYNOPSIS
    Show common AD attributes for a user (or users).
  .EXAMPLE
    Get-AdUserInfo jdoe
  .EXAMPLE
    Get-AdUserInfo jdoe -Credential (Get-Credential) -Server dc01
  #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0)]
    [string[]]$Identity = @($env:USERNAME),

    [pscredential]$Credential,
    [string]$Server
  )

  $common = @{}
  if ($Credential) { $common.Credential = $Credential }
  if ($Server)     { $common.Server     = $Server }

  foreach ($User in $Identity) {
    try {
      Get-ADUser -Identity $User -Properties DisplayName, EmailAddress, Enabled,
        LockedOut, LastLogonDate, PasswordLastSet, PasswordExpired,
        Title, Department, Company @common -ErrorAction Stop |
        Select-Object SamAccountName, DisplayName, EmailAddress, Enabled,
          LockedOut, Title, Department, LastLogonDate, PasswordLastSet, PasswordExpired
    }
    catch {
      Write-Error "Failed to retrieve user '$User': $_"
    }
  }
}

Function Get-AdGroupMembers {
  <#
  .SYNOPSIS
    List the members of an AD group.
  .PARAMETER Recursive
    Include members of nested groups.
  .EXAMPLE
    Get-AdGroupMembers 'Domain Admins'
  .EXAMPLE
    Get-AdGroupMembers 'All Staff' -Recursive -Credential (Get-Credential)
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Group,

    [switch]$Recursive,

    [pscredential]$Credential,
    [string]$Server
  )

  $common = @{}
  if ($Credential) { $common.Credential = $Credential }
  if ($Server)     { $common.Server     = $Server }

  try {
    Get-ADGroupMember -Identity $Group -Recursive:$Recursive @common -ErrorAction Stop |
      Sort-Object name |
      Select-Object Name, SamAccountName, objectClass, distinguishedName
  }
  catch {
    Write-Error "Failed to retrieve members of group '$Group': $_"
  }
}

Function Get-LockedAdUsers {
  <#
  .SYNOPSIS
    Find AD accounts that are currently locked out.
  .EXAMPLE
    Get-LockedAdUsers
  .EXAMPLE
    Get-LockedAdUsers -Credential (Get-Credential) -Server dc01
  #>
  [CmdletBinding()]
  param(
    [pscredential]$Credential,
    [string]$Server
  )

  $common = @{}
  if ($Credential) { $common.Credential = $Credential }
  if ($Server)     { $common.Server     = $Server }

  try {
    Search-ADAccount -LockedOut -UsersOnly @common -ErrorAction Stop |
      Sort-Object SamAccountName |
      Select-Object SamAccountName, Name, Enabled, LastLogonDate, DistinguishedName
  }
  catch {
    Write-Error "Failed to search for locked accounts: $_"
  }
}
