## Motd-AsciiArt  --  from 20_functions_fs.ps1 (one-file-per-function layout)

Function Motd-AsciiArt(){
  If ($ShowStartupArt){
    . $env:USERPROFILE\Documents\Powershell\ascii-art.ps1
    If ($PSVersionTable.PSVersion.Major -eq 7){
      Write-Output "`e[0;38;5;196m$GRIMREAPER`e[0m"
      Write-Output "`e[0;1;38;5;15m=============================================`e[0m"
    }
    Else {
      "$GRIMREAPER"
    }
  }
}

## Logging function
