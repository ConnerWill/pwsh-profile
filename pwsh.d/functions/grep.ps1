## grep  --  a Linux-like text search built on Select-String.
## Recurse directories, grep files by glob, or filter piped input.

Function grep {
  <#
  .SYNOPSIS
    Search text like Linux 'grep' (wraps Select-String).

  .DESCRIPTION
    Search piped input, one or more files, or recurse a directory tree.
    Mirrors the common grep flags so muscle memory carries over. Each short
    flag also has a readable long-form alias (shown in parentheses):
      -r / -R   recurse into directories            (-Recurse / -Recursive)
      -i        case-insensitive                     (-IgnoreCase)
      -v        invert match (lines that do NOT match)(-Invert / -InvertMatch)
      -l        list only the names of matching files (-FilesWithMatches / -List)
      -c        print only a count of matching lines  (-Count)
      -n        prefix matches with their line number (-LineNumber)
      -w        match whole words only                (-Word / -WordRegexp)
      -F        treat PATTERN as a literal string      (-Fixed / -FixedStrings)
      -include  glob to restrict which files are searched when recursing (-Include)

  .PARAMETER Pattern
    Regex (or literal string with -F) to search for.

  .PARAMETER Path
    Files or directories to search. If omitted, reads from the pipeline.

  .EXAMPLE
    grep TODO                       # search piped input:  Get-Content x | grep TODO
  .EXAMPLE
    grep -i error app.log           # case-insensitive search of a file
  .EXAMPLE
    grep -r 'Set-Alias' .           # recurse the current directory
  .EXAMPLE
    grep -r --include *.ps1 Function pwsh.d   # recurse, only *.ps1 files
  .EXAMPLE
    grep -rl password .             # just the filenames that match
  .EXAMPLE
    Get-Process | grep -i chrome    # filter any piped text
  #>
  [CmdletBinding()]
  [Alias('rg')]
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Pattern,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Path,

    [Alias('Recurse', 'Recursive')]        [switch]$r,   # recurse (-r / -R)
    [Alias('IgnoreCase')]                  [switch]$i,   # case-insensitive
    [Alias('Invert', 'InvertMatch')]       [switch]$v,   # invert match
    [Alias('FilesWithMatches', 'List')]    [switch]$l,   # files-with-matches only
    [Alias('Count')]                       [switch]$c,   # count only
    [Alias('LineNumber')]                  [switch]$n,   # show line numbers
    [Alias('Word', 'WordRegexp')]          [switch]$w,   # whole word
    [Alias('Fixed', 'FixedStrings')]       [switch]$F,   # fixed/literal string
    [string]$Include = '*',   # file glob when recursing (-Include)

    [Parameter(ValueFromPipeline)]
    [string[]]$InputObject
  )

  begin {
    $common = @{
      Pattern      = $Pattern
      SimpleMatch  = [bool]$F
      CaseSensitive = -not $i
      NotMatch     = [bool]$v
    }
    if ($w -and -not $F) { $common.Pattern = "\b$Pattern\b" }

    # Collect piped lines so we can search them if no Path is given.
    $pipeBuffer = [System.Collections.Generic.List[string]]::new()
  }

  process {
    if ($InputObject) { foreach ($line in $InputObject) { $pipeBuffer.Add($line) } }
  }

  end {
    # Decide the source: explicit paths, or the piped buffer.
    $results =
      if ($Path) {
        $files =
          if ($r) {
            Get-ChildItem -Path $Path -Recurse -File -Filter $Include -ErrorAction SilentlyContinue
          }
          else {
            # Expand globs/dirs; a bare dir with no -r is searched non-recursively.
            Get-Item -Path $Path -ErrorAction SilentlyContinue | ForEach-Object {
              if ($_.PSIsContainer) {
                Get-ChildItem -Path $_.FullName -File -Filter $Include -ErrorAction SilentlyContinue
              }
              else { $_ }
            }
          }
        $files | Select-String @common
      }
      else {
        $pipeBuffer | Select-String @common
      }

    if (-not $results) { return }

    if ($l) {
      # Unique filenames that contained a match.
      $results.Path | Sort-Object -Unique
    }
    elseif ($c) {
      # grep -c: count per file (or total for piped input).
      if ($Path) {
        $results | Group-Object Path | ForEach-Object {
          '{0}:{1}' -f $_.Name, $_.Count
        }
      }
      else { $results.Count }
    }
    else {
      $results | ForEach-Object {
        # Build an output line that reads like grep.
        $prefix = ''
        if ($Path -and @($results.Path | Sort-Object -Unique).Count -gt 1) {
          $prefix += "$($_.Filename):"
        }
        if ($n -or $Path) { $prefix += "$($_.LineNumber):" }
        '{0}{1}' -f $prefix, $_.Line.TrimEnd()
      }
    }
  }
}
