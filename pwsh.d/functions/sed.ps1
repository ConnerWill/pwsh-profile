## sed  --  stream editor: s/find/replace/ substitution (subset of Linux sed).

Function sed {
  <#
  .SYNOPSIS
    Substitute text with an 's/find/replace/' expression (subset of Linux sed).
  .DESCRIPTION
    Applies a sed-style substitution to piped input or to one or more files.
    Supports the substitute command 's/PATTERN/REPLACEMENT/[flags]' where:
      * PATTERN is a .NET regex
      * any single character may be used as the delimiter (e.g. 's|a|b|')
      * flags: 'g' (replace all on a line; default replaces only the first),
               'i' (case-insensitive)
    By default results are written to the pipeline (like sed to stdout). With
    -InPlace the matched files are rewritten. Captures ($1, ${name}) work in
    the replacement.
  .PARAMETER Script
    The sed substitution expression, e.g. 's/foo/bar/g'.
  .PARAMETER Path
    Optional file(s) to edit. If omitted, reads from the pipeline.
  .PARAMETER InputObject
    Pipeline text (bound automatically).
  .PARAMETER InPlace
    Rewrite the given files in place instead of writing to the pipeline.
  .EXAMPLE
    Get-Content app.log | sed 's/ERROR/WARN/g'
    Replace every ERROR with WARN in piped input.
  .EXAMPLE
    sed 's/foo/bar/' file.txt
    Replace the first 'foo' on each line of file.txt, printing the result.
  .EXAMPLE
    sed 's|/usr/local|/opt|g' paths.txt
    Use '|' as the delimiter (handy when the pattern contains '/').
  .EXAMPLE
    sed -InPlace 's/\s+$//' *.md
    Strip trailing whitespace from every .md file, rewriting them in place.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Script,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Path,

    [Parameter(ValueFromPipeline)]
    [string[]]$InputObject,

    [switch]$InPlace
  )

  begin {
    # Parse 's<delim>pattern<delim>replacement<delim>flags'.
    if ($Script -notmatch '^s(.)') {
      throw "sed: only the substitute command is supported, e.g. 's/find/replace/g'."
    }
    $delim = $Matches[1]
    $d = [regex]::Escape($delim)
    if ($Script -notmatch "^s$d(.*?)(?<!\\)$d(.*?)(?<!\\)$d([gi]*)$") {
      throw "sed: could not parse substitution '$Script'. Expected s${delim}find${delim}replace${delim}[gi]."
    }
    $pattern     = $Matches[1] -replace "\\$d", $delim
    $replacement = $Matches[2] -replace "\\$d", $delim
    $flags       = $Matches[3]

    $opts = [System.Text.RegularExpressions.RegexOptions]::None
    if ($flags -match 'i') { $opts = $opts -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
    $global_ = $flags -match 'g'
    $re = [regex]::new($pattern, $opts)

    $apply = { param($line) if ($global_) { $re.Replace($line, $replacement) } else { $re.Replace($line, $replacement, 1) } }
    $pipeBuffer = [System.Collections.Generic.List[string]]::new()
  }

  process {
    if ($InputObject) { foreach ($l in $InputObject) { $pipeBuffer.Add($l) } }
  }

  end {
    if ($Path) {
      foreach ($p in $Path) {
        $files = Get-ChildItem -Path $p -File -ErrorAction SilentlyContinue
        foreach ($file in $files) {
          $lines = Get-Content -LiteralPath $file.FullName
          $out = foreach ($line in $lines) { & $apply $line }
          if ($InPlace) {
            Set-Content -LiteralPath $file.FullName -Value $out
          }
          else { $out }
        }
      }
    }
    else {
      foreach ($line in $pipeBuffer) { & $apply $line }
    }
  }
}
