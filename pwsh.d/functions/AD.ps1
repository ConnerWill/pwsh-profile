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
  .DESCRIPTION
    Returns the Active Directory group memberships for one or more users, sorted
    by group name, with the user, group name, category, and scope. Defaults to
    the current user. Requires the ActiveDirectory module (RSAT); failures per
    user are reported without aborting the whole run.
  .PARAMETER Identity
    One or more user identities (sAMAccountName, DN, SID, etc.). Defaults to the
    current username.
  .PARAMETER Credential
    Optional credential to run the query as (you need not be logged in as them).
  .PARAMETER Server
    Optional domain controller / server to target.
  .EXAMPLE
    Get-UserAdGroupMembership
    Groups for the current user.
  .EXAMPLE
    Get-UserAdGroupMembership jdoe, asmith
    Groups for two named users.
  .EXAMPLE
    Get-UserAdGroupMembership jdoe -Credential (Get-Credential) -Server dc01
    Run against a specific DC using supplied credentials.
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
  .DESCRIPTION
    Retrieves a focused set of frequently-needed Active Directory attributes for
    one or more users: display name, email, enabled/locked status, title and
    department, last logon, and password state. Defaults to the current user.
    Requires the ActiveDirectory module (RSAT); per-user failures are reported
    without stopping the run.
  .PARAMETER Identity
    One or more user identities (sAMAccountName, DN, SID, etc.). Defaults to the
    current username.
  .PARAMETER Credential
    Optional credential to run the query as.
  .PARAMETER Server
    Optional domain controller / server to target.
  .EXAMPLE
    Get-AdUserInfo jdoe
    Show key attributes for a single user.
  .EXAMPLE
    Get-AdUserInfo jdoe, asmith
    Show attributes for several users at once.
  .EXAMPLE
    Get-AdUserInfo jdoe -Credential (Get-Credential) -Server dc01
    Query a specific DC with supplied credentials.
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
  .DESCRIPTION
    Returns the members of an Active Directory group, sorted by name, with each
    member's name, sAMAccountName, object class, and distinguished name. Use
    -Recursive to flatten nested group memberships. Requires the ActiveDirectory
    module (RSAT); failures report a clear error.
  .PARAMETER Group
    The target group's name (or identity) to enumerate.
  .PARAMETER Recursive
    Include members of nested groups (flatten the hierarchy).
  .PARAMETER Credential
    Optional credential to run the query as.
  .PARAMETER Server
    Optional domain controller / server to target.
  .EXAMPLE
    Get-AdGroupMembers 'Domain Admins'
    List the direct members of a group.
  .EXAMPLE
    Get-AdGroupMembers 'All Staff' -Recursive
    Include members of nested groups.
  .EXAMPLE
    Get-AdGroupMembers 'All Staff' -Recursive -Credential (Get-Credential)
    Recurse, using supplied credentials.
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
  .DESCRIPTION
    Searches Active Directory for user accounts in a locked-out state and lists
    each one's sAMAccountName, name, enabled status, last logon, and DN, sorted
    by account name. Requires the ActiveDirectory module (RSAT); a failed search
    reports a clear error.
  .PARAMETER Credential
    Optional credential to run the search as.
  .PARAMETER Server
    Optional domain controller / server to target.
  .EXAMPLE
    Get-LockedAdUsers
    List all currently locked-out user accounts.
  .EXAMPLE
    Get-LockedAdUsers -Credential (Get-Credential) -Server dc01
    Search a specific DC with supplied credentials.
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
