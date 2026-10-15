## e  --  from 20_functions_fs.ps1 (one-file-per-function layout)

Function e(){
  <#
  .SYNOPSIS
    Open your configured editor ($EDITOR), optionally on a path.
  .DESCRIPTION
    Launches the editor named in $EDITOR. With no argument it opens the editor
    empty; with a path it opens that file or directory. Errors clearly if the
    configured editor isn't found on PATH.
  .PARAMETER Path
    Optional file or directory to open.
  .EXAMPLE
    e
    Open the editor with no file.
  .EXAMPLE
    e profile.ps1
    Open a specific file.
  .EXAMPLE
    e .
    Open the current directory in the editor.
  #>
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
