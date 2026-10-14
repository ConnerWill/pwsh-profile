## Encode-Command  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

function Encode-Command($command){
  $bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
  $encodedCommand = [Convert]::ToBase64String($bytes)
  echo "pwsh -NoLogo -NoProfile -encodedcommand $encodedCommand" | Set-Clipboard
  Write-Output "pwsh -NoLogo -NoProfile -encodedcommand $encodedCommand"
}
