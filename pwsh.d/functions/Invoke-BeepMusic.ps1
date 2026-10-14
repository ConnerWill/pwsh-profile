## Invoke-BeepMusic  --  random tones via the PC speaker / console beep.

Function Invoke-BeepMusic {
  <#
  .SYNOPSIS
    Play a sequence of random beeps (toy "music") through the console speaker.

  .DESCRIPTION
    Picks random notes from a scale and plays them with random durations.
    Windows only ([Console]::Beep). By default it plays a fixed number of
    notes; use -Infinite to loop until Ctrl+C.

  .PARAMETER Count
    How many notes to play (ignored when -Infinite is set). Default 32.

  .PARAMETER Infinite
    Loop forever until you press Ctrl+C.

  .PARAMETER Notes
    Frequencies (Hz) to choose from. Defaults to a C-major-ish scale.

  .PARAMETER MinDuration
    Shortest note length in ms (default 100).

  .PARAMETER MaxDuration
    Longest note length in ms (default 400).

  .PARAMETER Gap
    Silence between notes in ms (default 50).

  .EXAMPLE
    Invoke-BeepMusic

  .EXAMPLE
    Invoke-BeepMusic -Count 100

  .EXAMPLE
    Invoke-BeepMusic -Infinite        # Ctrl+C to stop
  #>
  [CmdletBinding()]
  [Alias('beepmusic')]
  param(
    [int]$Count = 32,
    [switch]$Infinite,
    [int[]]$Notes = @(262, 294, 330, 349, 392, 440, 494),  # C D E F G A B
    [ValidateRange(1, 20000)][int]$MinDuration = 100,
    [ValidateRange(1, 20000)][int]$MaxDuration = 400,
    [ValidateRange(0, 10000)][int]$Gap = 50
  )

  if (-not ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop')) {
    Write-Warning 'Invoke-BeepMusic needs Windows ([Console]::Beep is Windows-only).'
    return
  }
  if ($MaxDuration -lt $MinDuration) {
    throw "MaxDuration ($MaxDuration) must be >= MinDuration ($MinDuration)."
  }

  $played = 0
  try {
    while ($Infinite -or $played -lt $Count) {
      $note     = $Notes | Get-Random
      $duration = Get-Random -Minimum $MinDuration -Maximum ($MaxDuration + 1)
      [Console]::Beep($note, $duration)
      if ($Gap -gt 0) { Start-Sleep -Milliseconds $Gap }
      $played++
    }
  }
  catch [System.Management.Automation.PipelineStoppedException] {
    # Ctrl+C -- stop quietly (no output). No-op keeps the linter happy.
    $null = $_
  }
}
