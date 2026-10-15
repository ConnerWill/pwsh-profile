## Encode-Command  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

function Encode-Command($command){
  <#
  .SYNOPSIS
    Base64-encode a command for 'pwsh -EncodedCommand' and copy it to the clipboard.
  .DESCRIPTION
    Encodes the given command text as UTF-16LE Base64 (the format pwsh expects for
    -EncodedCommand), copies the full 'pwsh -NoLogo -NoProfile -encodedcommand ...'
    invocation to the clipboard, and also writes it to the pipeline. Handy for
    passing a command through tools that mangle quotes/spaces.
  .PARAMETER command
    The command text to encode.
  .EXAMPLE
    Encode-Command 'Get-Process | Sort CPU -Descending'
    Copies a ready-to-run 'pwsh -encodedcommand ...' line to the clipboard.
  .EXAMPLE
    Encode-Command "Write-Host 'hi there'"
    Encodes a command containing spaces and quotes.
  #>
  $bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
  $encodedCommand = [Convert]::ToBase64String($bytes)
  echo "pwsh -NoLogo -NoProfile -encodedcommand $encodedCommand" | Set-Clipboard
  Write-Output "pwsh -NoLogo -NoProfile -encodedcommand $encodedCommand"
}
