## e  --  from 20_functions_fs.ps1 (one-file-per-function layout)

Function e(){
  [CmdletBinding()]
  Param([Parameter(Position = 0,ValueFromPipeline = $True,ValueFromRemainingArguments = $True,Mandatory = $False)]
  [string]$Path)

  # Resolve the configured editor; fail with a clear message if it's missing.
  if (-not (Get-Command $EDITOR -ErrorAction Ignore)) {
    Write-Error "Editor '$EDITOR' not found on PATH. Set `$EDITOR in profile.ps1."
    return
  }
  # No path given -> just open the editor (don't pass $PWD, which would make the
  # editor try to open every file in the current directory).
  if ([string]::IsNullOrWhiteSpace($Path)) {
    & $EDITOR
  }
  else {
    & $EDITOR $Path
  }
}
