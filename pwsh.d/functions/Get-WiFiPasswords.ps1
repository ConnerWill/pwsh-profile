## Get-WiFiPasswords  --  from 24_functions_system.ps1 (one-file-per-function layout)

Function Get-WiFiPasswords(){
#\ function Get-WiFiPasswords(){(netsh wlan show profiles) | Select-String "\:(.+)$" | %{$name=$_.Matches.Groups[1].Value.Trim(); $_} | %{(netsh wlan show profile name="$name" key=clear)}  | Select-String "Key Content\W+\:(.+)$" | %{$pass=$_.Matches.Groups[1].Value.Trim(); $_} | %{[PSCustomObject]@{ PROFILE_NAME=$name;PASSWORD=$pass }} | Format-Table -AutoSize}
    (netsh wlan show profiles) | Select-String "\:(.+)$" | ForEach-Object{
      $name=$_.Matches.Groups[1].Value.Trim(); $_
    } | ForEach-Object{
          (netsh wlan show profile name="$name" key=clear)
        } | Select-String "Key Content\W+\:(.+)$" | ForEach-Object{
                $pass=$_.Matches.Groups[1].Value.Trim(); $_
              } | ForEach-Object{
                    [PSCustomObject]@{
                      PROFILE_NAME=$name;PASSWORD=$pass
                    }
                  } | Format-Table -AutoSize
}

###}}} END FUNCTIONS
