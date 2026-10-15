## Start_PSTranscript  --  from 24_functions_system.ps1 (one-file-per-function layout)

Function Start_PSTranscript(){
  <#
  .SYNOPSIS
    Start a timestamped PowerShell session transcript (with log rotation).
  .DESCRIPTION
    Begins recording the session to a timestamped .log in $PS_TRANSCRIPT_DIR,
    creating the directory if needed and pruning old transcripts beyond
    $PS_TRANSCRIPT_MAX. Stops any already-running transcript first so reloads
    don't stack. Honors these overridable variables:
      $PS_TRANSCRIPT_ENABLED  (on/off)   $PS_TRANSCRIPT_DIR   (output folder)
      $PS_TRANSCRIPT_MAX      (keep N; 0 = no pruning)
    This runs automatically when the profile loads; call it manually to restart
    transcription after stopping it.
  .EXAMPLE
    Start_PSTranscript
    Start (or restart) recording the current session.
  #>
  if (-not $PS_TRANSCRIPT_ENABLED){ return }

  # Ensure the directory exists (no recursion: just create it, then continue).
  if (-not (Test-Path -Path $PS_TRANSCRIPT_DIR)){
    try { New-Item -Path $PS_TRANSCRIPT_DIR -ItemType Directory -Force -ErrorAction Stop | Out-Null }
    catch { Write-Warning "Transcript dir unavailable: $PS_TRANSCRIPT_DIR"; return }
  }

  # Prune old transcripts so the directory doesn't grow without bound.
  $max = if ($PS_TRANSCRIPT_MAX -is [int]) { $PS_TRANSCRIPT_MAX } else { 50 }
  if ($max -gt 0){
    Get-ChildItem -Path $PS_TRANSCRIPT_DIR -Filter 'PowerShell_transcript.*.log' -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -Skip $max |
      Remove-Item -Force -ErrorAction SilentlyContinue
  }

  # If a transcript is already running (e.g. after Reload-Profile), stop it first
  # so we don't stack transcripts. Stop-Transcript throws when none is active, so
  # swallow that case.
  try { Stop-Transcript | Out-Null } catch { }

  $CurrentDate = Get-Date -Format 'yyyyMMddHHmmss'
  Start-Transcript -Path "$PS_TRANSCRIPT_DIR\PowerShell_transcript.$CurrentDate.log" >$null 2>&1
}; Start_PSTranscript

## LS functions
