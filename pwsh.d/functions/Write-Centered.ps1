## Write-Centered  --  print text centered in the terminal width, optionally colored.
## PowerShell equivalent of the zsh _ez_printcentered helper.

Function Write-Centered {
  <#
  .SYNOPSIS
    Print text centered across the terminal width.
  .DESCRIPTION
    Pads a string on both sides so it sits centered in the current console
    width (falling back to 80 columns when the width can't be determined, e.g.
    redirected output). Optionally colors the text with a 256-color value and
    pads with a custom fill character to create a titled rule. With -NoNewline
    the line is written without a trailing newline, which is useful for in-place
    overwrite effects (e.g. a transient "Reloading ..." banner).
  .PARAMETER Text
    The text to center.
  .PARAMETER Color
    256-color value for the text (optional; no color when omitted).
  .PARAMETER Fill
    Character used to pad each side (default: space).
  .PARAMETER NoNewline
    Don't emit a trailing newline (useful for in-place overwrite effects).
  .EXAMPLE
    Write-Centered 'Reloading ...' -Color 46
    Center a green status message across the terminal.
  .EXAMPLE
    Write-Centered 'WELCOME' -Fill '=' -Color 33
    Make a centered title padded with '=' on both sides.
  .EXAMPLE
    Write-Centered 'working' -NoNewline; Start-Sleep 1; Write-Host "`rdone"
    Overwrite a centered line in place (no trailing newline).
  .EXAMPLE
    'one','two' | ForEach-Object { center $_ }
    Center several strings via the 'center' alias.
  #>
  [CmdletBinding()]
  [Alias('center')]
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Text,

    [int]$Color,
    [char]$Fill = ' ',
    [switch]$NoNewline
  )

  # Terminal width, falling back to 80 when it can't be determined
  # (e.g. redirected output / no console).
  $cols = try { [Console]::WindowWidth } catch { 0 }
  if ($cols -le 0) { $cols = 80 }

  $len = $Text.Length
  if ($len -ge $cols) {
    # Too long to center; just print it.
    $padded = $Text
  }
  else {
    $fillLen = [int](($cols - $len) / 2)
    $pad = [string]$Fill * $fillLen
    $padded = $pad + $Text + $pad
    # If the gap was odd, add one more fill char so the line is full width.
    if ((($cols - $len) % 2) -ne 0) { $padded += [string]$Fill }
  }

  $e = "`e"
  $open  = if ($PSBoundParameters.ContainsKey('Color')) { "$e[38;5;${Color}m" } else { '' }
  $close = if ($open) { "$e[0m" } else { '' }

  if ($NoNewline) { [Console]::Write("$open$padded$close") }
  else            { [Console]::WriteLine("$open$padded$close") }
}
