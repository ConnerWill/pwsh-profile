## touch  --  from 20_functions_fs.ps1 (one-file-per-function layout)

Function touch {
  <#
  .SYNOPSIS
    Update a file's timestamps, creating it (empty) if it doesn't exist.

  .DESCRIPTION
    Behaves like Linux 'touch':
      * If the file exists, its LastWriteTime (and LastAccessTime) are bumped to
        now -- the content is left untouched.
      * If it doesn't exist, an empty file is created.
    Accepts multiple paths and pipeline input. Missing parent directories are
    created automatically. Use -NoCreate to only update existing files (like
    'touch -c'), and -Date to set a specific timestamp instead of 'now'.

  .PARAMETER Path
    One or more file paths to touch. Accepts pipeline input and remaining args.
  .PARAMETER NoCreate
    Do not create files that don't exist (like 'touch -c').
  .PARAMETER Date
    Timestamp to apply instead of the current time (like 'touch -d').

  .EXAMPLE
    touch new_file.txt
    Create an empty file (or bump its timestamp if it already exists).

  .EXAMPLE
    touch a.txt b.txt c.txt
    Touch several files at once.

  .EXAMPLE
    touch logs\today.log
    Creates the 'logs' directory too if it's missing.

  .EXAMPLE
    'one.txt','two.txt' | touch -NoCreate
    Only update timestamps of files that already exist.
  #>
  [CmdletBinding(SupportsShouldProcess)]
  Param (
    [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
    [Alias('Name', 'FullName')]
    [string[]]$Path,

    [switch]$NoCreate,

    [datetime]$Date = (Get-Date)
  )

  process {
    foreach ($p in $Path) {
      if ([string]::IsNullOrWhiteSpace($p)) { continue }

      if (Test-Path -LiteralPath $p) {
        # Exists: just update the timestamps (don't touch content).
        if ($PSCmdlet.ShouldProcess($p, 'Update timestamps')) {
          try {
            $item = Get-Item -LiteralPath $p -Force -ErrorAction Stop
            $item.LastWriteTime  = $Date
            $item.LastAccessTime = $Date
          }
          catch { Write-Error "Failed to update timestamps for '$p': $($_.Exception.Message)" }
        }
        continue
      }

      if ($NoCreate) { continue }   # 'touch -c': skip creation

      if ($PSCmdlet.ShouldProcess($p, 'Create empty file')) {
        try {
          # Create any missing parent directories first.
          $parent = Split-Path -Path $p -Parent
          if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
          }
          New-Item -ItemType File -Path $p -ErrorAction Stop | Out-Null
          # Honor an explicit -Date on freshly created files too.
          if ($PSBoundParameters.ContainsKey('Date')) {
            $item = Get-Item -LiteralPath $p -Force
            $item.LastWriteTime  = $Date
            $item.LastAccessTime = $Date
          }
        }
        catch { Write-Error "Failed to create file '$p': $($_.Exception.Message)" }
      }
    }
  }
}
