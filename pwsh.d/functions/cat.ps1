## cat  --  view files with syntax highlighting via 'bat' when available,
## falling back to PowerShell's default Get-Content otherwise.

## 'cat' is a built-in alias for Get-Content. Remove it (if present) so our
## wrapper can take over. Guarded so re-sourcing (reload) doesn't throw.
if (Get-Alias -Name cat -ErrorAction Ignore) { Remove-Alias -Name cat -Force }

Function cat {
  <#
  .SYNOPSIS
    Show file contents with syntax highlighting (via 'bat'), or plain if bat
    isn't installed.
  .DESCRIPTION
    If the 'bat' tool (https://github.com/sharkdp/bat) is on PATH, files are
    displayed through it for syntax highlighting, line numbers, and paging.
    Otherwise this transparently falls back to PowerShell's built-in Get-Content
    so 'cat' always works -- highlighted on machines that have bat, plain on
    those that don't (e.g. a fresh Windows box before bat is installed).

    Extra arguments are passed straight through to bat, so bat flags like
    --plain, --language, or --line-range work when bat is present.
  .PARAMETER Path
    One or more files to display. Accepts pipeline input and remaining args.
  .EXAMPLE
    cat profile.ps1
    Highlighted view via bat (or plain content if bat isn't installed).
  .EXAMPLE
    cat script.ps1 README.md
    Show several files.
  .EXAMPLE
    cat app.log --line-range 1:40
    Pass bat flags through (only effective when bat is installed).
  .EXAMPLE
    'a.txt','b.txt' | cat
    Pipe file paths in.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
    [string[]]$Path
  )

  begin {
    $bat = Get-Command bat -CommandType Application -ErrorAction Ignore |
      Select-Object -First 1
    $items = [System.Collections.Generic.List[string]]::new()
  }

  process {
    if ($Path) { foreach ($p in $Path) { $items.Add($p) } }
  }

  end {
    if ($items.Count -eq 0) { return }

    if ($bat) {
      & $bat.Source @items
    }
    else {
      # Plain fallback: default Get-Content behavior. Separate the (likely) file
      # paths from any pass-through flags (bat-only) so Get-Content doesn't choke.
      $files = $items | Where-Object { $_ -notmatch '^-' }
      if ($files) { Get-Content -Path $files }
    }
  }
}
