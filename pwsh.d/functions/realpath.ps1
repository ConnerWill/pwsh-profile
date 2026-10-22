## realpath (alias rp): resolve a path to its absolute, canonical form
## (like 'realpath' in linux). Resolves .., ~, and relative paths. Works for
## paths that don't exist yet, too. Defaults to the current directory.
## ('rp' is a built-in alias for Remove-ItemProperty; drop it so ours wins.
## Guarded so re-sourcing doesn't throw.)
if (Get-Alias -Name rp -ErrorAction Ignore) { Remove-Alias -Name rp -Force }

Function realpath {
  <#
  .SYNOPSIS
    Resolve a path to its absolute, canonical form (like Linux 'realpath').
  .DESCRIPTION
    Expands '..', '~', and relative segments into a full absolute path. Resolves
    existing items through the provider; for paths that don't exist yet it falls
    back to normalizing against the current directory. Accepts multiple paths and
    pipeline input, and defaults to the current directory.
  .PARAMETER Path
    One or more paths to resolve (default: '.'). Accepts pipeline input.
  .EXAMPLE
    realpath ..\foo
    Resolve a relative path to its absolute form.
  .EXAMPLE
    rp ~/Documents
    Expand '~' to the full home path (via the 'rp' alias).
  .EXAMPLE
    '.', '..', 'nope.txt' | realpath
    Resolve several paths from the pipeline (including a non-existent one).
  #>
  [CmdletBinding()]
  [Alias('rp')]
  param(
    [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
    [string[]]$Path = @('.')
  )
  process {
    foreach ($p in $Path) {
      # Try a real resolve first (follows the provider / existing items)...
      $resolved = Resolve-Path -LiteralPath $p -ErrorAction Ignore
      if ($resolved) { $resolved.Path }
      else {
        # ...fall back to GetFullPath for not-yet-existing paths, resolved
        # against the current directory.
        [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $p))
      }
    }
  }
}
