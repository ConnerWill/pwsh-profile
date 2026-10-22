## Encode-Command  --  from 21_functions_cmd.ps1 (one-file-per-function layout)

function Encode-Command {
  <#
  .SYNOPSIS
    Base64-encode a command for 'pwsh -EncodedCommand' and copy it to the clipboard.
  .DESCRIPTION
    Encodes the given command text as UTF-16LE Base64 (the format pwsh expects for
    -EncodedCommand), copies the full 'pwsh -NoLogo -NoProfile -EncodedCommand ...'
    invocation to the clipboard (when a clipboard is available), shows how to run
    it (syntax-colored like PowerShell's default tokens), and writes the encoded
    line to the output stream. Handy for passing a command through tools that
    mangle quotes/spaces.

    Accepts the command as an argument or from the pipeline. Use -Raw to emit
    only the Base64 token (no 'pwsh ...' wrapper), and -NoClipboard to skip the
    clipboard copy.
  .PARAMETER Command
    The command text to encode. Required; accepts pipeline input.
  .PARAMETER Raw
    Output only the Base64-encoded string, without the 'pwsh ...' wrapper.
  .PARAMETER NoClipboard
    Do not copy the result to the clipboard (just return it).
  .EXAMPLE
    Encode-Command 'Get-Process | Sort CPU -Descending'
    Copies a ready-to-run 'pwsh -EncodedCommand ...' line to the clipboard.
  .EXAMPLE
    Encode-Command "Write-Host 'hi there'"
    Encodes a command containing spaces and quotes.
  .EXAMPLE
    'Get-Date' | Encode-Command -Raw
    Pipe in a command and get back just the Base64 token.
  #>
  [CmdletBinding()]
  [OutputType([string])]
  [Alias('encmd')]
  param(
    [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromRemainingArguments)]
    [ValidateNotNullOrEmpty()]
    [string]$Command,

    [switch]$Raw,
    [switch]$NoClipboard
  )

  process {
    # Guard: -EncodedCommand requires non-empty input; bail clearly otherwise.
    if ([string]::IsNullOrWhiteSpace($Command)) {
      Write-Error 'Encode-Command: no command text supplied.'
      return
    }

    # pwsh -EncodedCommand expects UTF-16LE (Unicode) Base64.
    $bytes          = [System.Text.Encoding]::Unicode.GetBytes($Command)
    $encodedCommand = [Convert]::ToBase64String($bytes)

    $result = if ($Raw) {
      $encodedCommand
    }
    else {
      "pwsh -NoLogo -NoProfile -EncodedCommand $encodedCommand"
    }

    $copied = $false
    if (-not $NoClipboard) {
      # Set-Clipboard may be unavailable (headless/no GUI session); don't let a
      # clipboard failure swallow the result.
      try { $result | Set-Clipboard -ErrorAction Stop; $copied = $true }
      catch { Write-Warning "Could not copy to clipboard: $($_.Exception.Message)" }
    }

    # Show how to run it, syntax-colored from the profile's $Colors table (plain
    # when unavailable), mirroring PowerShell's default token colors:
    #   command name -> yellow, parameters (-Option) -> grey, arguments -> white.
    if ($Colors) {
      $cHead  = "$($Colors.Bold)$($Colors.Green)"
      $cCmd   = $Colors.Yellow                 # command name  (e.g. pwsh)
      $cParam = $Colors.Grey                   # -Option flags
      $cArg   = $Colors.White                  # option arguments
      $cReset = $Colors.Reset
    }
    else {
      $cHead = $cCmd = $cParam = $cArg = $cReset = ''
    }

    # Colorize an invocation line token-by-token to match PS default syntax
    # colors: first token (command) yellow, -Parameters grey, everything else
    # (arguments) white.
    $colorize = {
      param([string]$line)
      $tokens = $line -split ' '
      $parts  = for ($idx = 0; $idx -lt $tokens.Count; $idx++) {
        $tok = $tokens[$idx]
        if ($idx -eq 0)            { "${cCmd}${tok}${cReset}" }   # command name
        elseif ($tok -like '-*')   { "${cParam}${tok}${cReset}" } # parameter
        else                       { "${cArg}${tok}${cReset}" }   # argument
      }
      $parts -join ' '
    }

    $invocation = "pwsh -NoLogo -NoProfile -EncodedCommand $encodedCommand"

    if ($Raw) {
      # -Raw emits only the token; show the full invocation it plugs into.
      Write-Output "${cHead}Run with:${cReset}"
      Write-Output ("  " + (& $colorize $invocation))
    }
    else {
      Write-Output "${cHead}Run this command:${cReset}"
      Write-Output ("  " + (& $colorize $result))
    }
    if ($copied) { Write-Output "${cHead}(copied to clipboard)${cReset}" }

    Write-Output $result
  }
}
