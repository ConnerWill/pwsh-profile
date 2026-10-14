function Get-VaultCertificate(){
<#
.SYNOPSIS
    Downloads certificates from vault
.DESCRIPTION
    Download a certificate from HashiCorp Vault and copy the certificate password to clipboard
.PARAMETER VaultPath
    Path of item in Vault 
.PARAMETER VaultCredential
    Secure credentials to login to Vault
.PARAMETER Output
    Path to parent directory of output files
.EXAMPLE
    get-vaultcertificate -vaultpath "states_groups/state/city/campus.city.k12.state.country_date"

    Downloads certificate from Vault using the vault path of 'states_groups/state/city/campus.city.k12.state.country_date'
.EXAMPLE
    Get-VaultCertificate -VaultPath "states_groups/state/city/campus.city.k12.state.country_date" -Output "$HOME\ssl"

    Downloads certificate from Vault and saving output to the directory '$HOME\ssl'
.EXAMPLE
    Get-VaultCertificate -VaultPath "states_groups/state/city/campus.city.k12.state.country_date" -VaultCredential (Get-Credential)

    Downloads certificate from Vault using credentials
.EXAMPLE
    Get-VaultCertificate -VaultPath "states_groups/state/city/campus.city.k12.state.country_date" -VaultCredential $VaultCredential -Output "$HOME\ssl"

    Downloads certificate from Vault using credentials and saving the output files to the directory '$HOME\ssl'
.NOTES
    ===
#>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$True, Position=0, HelpMessage='Enter path in vault')][String]$VaultPath,
    [Parameter(Mandatory=$false, HelpMessage='Enter credentials')][SecureString]$VaultCredential,
    [Parameter(Mandatory=$false, HelpMessage='Enter parent directory of output ')][String]$Output
  )

  if($null -eq $token){
    if($null -eq $VaultCredentials){
      #ask for credentials to log in to vault
      Write-Output "`e[0;1;38;5;190mLogin to Vault`e[0m"
      $VaultCredential = Get-Credential -Message "Vault Credentials"
    }
    try {
      #use credentials to log in and get a token
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
      Write-Output "`e[0;1;38;5;190mPlease check your phone for an Okta push notification. `e[0;38;5;7mProcess will wait for Okta approval.`e[0m"
      $request = Invoke-WebRequest -Method POST -Body ('{"password": "' + $VaultCredential.GetNetworkCredential().Password + '"}') -Uri ('https://vault.infinitecampus.com/v1/auth/okta/login/' + $credential.GetNetworkCredential().Username)
      $json = ConvertFrom-Json -InputObject $request
      $token = $json.auth.client_token
    }
    catch {
      Write-Error "Unable to authenticate with Okta"
      Return
    }
  }

  #use token to fetch a secret
  try{
      $response = Invoke-WebRequest -Method GET -Uri ('https://vault.infinitecampus.com/v1/certificates/' + $VaultPath) -Headers @{'X-Vault-Token' =  $token;}
      $responseJson = ConvertFrom-Json -InputObject $response

      foreach($secret in $responseJson.data.PSObject.Properties){
          $secret.Value | Out-File -Encoding 'UTF8' -FilePath ($secret.Name)
      }
      ##this excludes characters & < > " ' ` ~ @ * ^ ; : [ ] { } # | $ !  they cause more problems then they are worth when entering into config files.
      $password = -join ((37..37 + 43..57 + 61 + 63 + 65..90 + 92 + 95 + 97..122) * 120 | Get-Random -Count 16 | ForEach-Object { [char]$_ })
      Write-Output "`e[0;38;5;190mYour .pfx password is:`t`e[0;1;5;46m$password`e[0m"
      ## Set password to clipboard
      try {
        $password | Set-Clipboard
      }
      catch {
        Write-Output "`e[0;38;5;196mUnable to set clipboard to .pfx password`e[0m"
      }
      try {      
        #bundle up the private key and certificates into a .pfx with a random strong password
        openssl pkcs12 -descert -macalg SHA1 -export -out ($VaultPath.split('/')[-1] + ".pfx") -inkey cert.key -in cert.crt -certfile caCerts.crt -password ('pass:'+ $password)
      }
      catch {
        $_.Exception.Message
        Return
      }
  }
  catch{
      $_.Exception.Message 
      Write-Output "`e[0;38;5;196mPlease vertify `e[0;1;38;5;190m'certificates/$VaultPath'`e[0;38;5;196m exists in vault`e[0m"
  }
}