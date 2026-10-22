## Show-RainbowLoadingBar  --  animated truecolor rainbow bar that sweeps the
## full terminal width. Port of the zsh install-dotfiles.sh loading bar.

Function Show-RainbowLoadingBar {
  <#
  .SYNOPSIS
    Draw an animated rainbow bar that fills the terminal width.
  .DESCRIPTION
    Sweeps a truecolor (24-bit) rainbow across the full console width, one column
    at a time, mapping each column onto the HSV color wheel. The cursor is hidden
    during the animation and restored afterward. -Duration controls the total
    sweep time; the per-column delay is derived from the terminal width. A port
    of the zsh install-dotfiles loading bar. Registered under the 'rainbow' alias.
  .PARAMETER Duration
    Approximate seconds for the full left-to-right sweep (default 1.5).
  .EXAMPLE
    Show-RainbowLoadingBar
    Run a ~1.5s rainbow sweep across the terminal.
  .EXAMPLE
    Show-RainbowLoadingBar -Duration 3
    A slower, 3-second sweep.
  .EXAMPLE
    rainbow
    Run it via the 'rainbow' alias.
  #>
  [CmdletBinding()]
  [Alias('rainbow')]
  param(
    [double]$Duration = 1.5
  )

  # Map an index 0-255 onto the HSV colour wheel -> r,g,b (each 0-255).
  function Script:_RainbowRGB([int]$n) {
    $h = [int]([math]::Floor($n / 43))
    $f = $n - 43 * $h
    $t = [int]($f * 255 / 43)
    $q = 255 - $t
    switch ($h) {
      0 { 255, $t, 0 }
      1 { $q, 255, 0 }
      2 { 0, 255, $t }
      3 { 0, $q, 255 }
      4 { $t, 0, 255 }
      default { 255, 0, $q }
    }
  }

  $cols = try { [Console]::WindowWidth } catch { 0 }
  if ($cols -le 0) { $cols = 80 }

  $delayMs = [int](($Duration * 1000) / $cols)
  $e = "`e"

  [Console]::Write("$e[?25l")   # hide cursor
  try {
    for ($i = 0; $i -lt $cols; $i++) {
      $step = if ($cols -gt 1) { [int]($i * 255 / ($cols - 1)) } else { 0 }
      $rgb = _RainbowRGB $step
      [Console]::Write("$e[48;2;$($rgb[0]);$($rgb[1]);$($rgb[2])m ")
      if ($delayMs -gt 0) { Start-Sleep -Milliseconds $delayMs }
    }
  }
  finally {
    [Console]::Write("$e[0m$e[?25h`n")   # reset colour, restore cursor, newline
  }
}
