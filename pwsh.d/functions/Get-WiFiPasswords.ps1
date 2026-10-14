## Get-WiFiPasswords  --  from 24_functions_system.ps1 (one-file-per-function layout)

Function Get-WiFiPasswords {
  <#
  .SYNOPSIS
    List saved Wi-Fi networks and their passwords (Windows).

  .DESCRIPTION
    Reads the WLAN profiles known to Windows via `netsh` and returns one object
    per network with its SSID, authentication type, and plaintext key (or
    '<none>' for open networks). Output is sorted by SSID and formatted as a
    table. Requires Windows; needs an elevated session for some profiles.

  .EXAMPLE
    Get-WiFiPasswords

  .EXAMPLE
    Get-WiFiPasswords | Where-Object Password -ne '<none>'

  .EXAMPLE
    Get-WiFiPasswords | Export-Csv wifi.csv -NoTypeInformation
  #>
  [CmdletBinding()]
  [OutputType('PSCustomObject')]
  param()

  if (-not $IsWindows -and $PSVersionTable.PSEdition -ne 'Desktop') {
    Write-Warning 'Get-WiFiPasswords requires Windows (uses netsh wlan).'
    return
  }

  # Collect SSIDs from the profile list ("All User Profile : <name>").
  $profiles =
    netsh wlan show profiles |
      Select-String -Pattern 'All User Profile\s*:\s*(.+)$' |
      ForEach-Object { $_.Matches.Groups[1].Value.Trim() } |
      Sort-Object -Unique

  if (-not $profiles) {
    Write-Warning 'No saved Wi-Fi profiles found.'
    return
  }

  $results = foreach ($ssid in $profiles) {
    $detail = netsh wlan show profile name="$ssid" key=clear

    $auth = ($detail | Select-String -Pattern 'Authentication\s*:\s*(.+)$' |
             Select-Object -First 1).Matches.Groups[1].Value.Trim()

    $keyLine = $detail | Select-String -Pattern 'Key Content\s*:\s*(.+)$' |
               Select-Object -First 1
    $pass = if ($keyLine) { $keyLine.Matches.Groups[1].Value.Trim() } else { '<none>' }

    [PSCustomObject]@{
      SSID           = $ssid
      Authentication = if ($auth) { $auth } else { 'Unknown' }
      Password       = $pass
    }
  }

  $results | Sort-Object SSID | Format-Table -AutoSize
}
