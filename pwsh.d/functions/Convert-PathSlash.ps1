## Convert-PathSlash  --  flip path separators (and tidy the result).
## PowerShell port of the zsh `replace-backslashes-with-forward` helper, extended
## with a reverse direction, Windows drive-letter handling, and slash collapsing.

Function Convert-PathSlash {
  <#
  .SYNOPSIS
    Convert path separators between Windows '\' and Unix '/' (with extras).

  .DESCRIPTION
    By default this mirrors the zsh `replace-backslashes-with-forward`:
    every backslash becomes a forward slash and a single leading '/' is
    prepended -- handy for pasting a Windows path into a Unix-y context.

    Extensions (all opt-in, so the default output matches the original):
      -ToWindows       Reverse direction: '/' -> '\' (and no leading slash).
      -DriveStyle      Rewrite a Windows drive path to MSYS/Git-Bash form,
                       e.g. 'C:\Users' -> '/c/Users' (lowercased drive, the
                       ':' dropped). Implies forward-slash output.
      -NoLeadingSlash  Don't prepend the leading '/' (forward direction only).

    Duplicate separators are collapsed ('a//b' -> 'a/b', 'a\\b' -> 'a\b'),
    except for a leading UNC-style '\\' which is preserved when going -ToWindows.

    Accepts one or more strings as arguments or from the pipeline. Like the zsh
    version, multiple arguments are treated as a single space-joined string.

  .PARAMETER Path
    One or more path strings to convert. Accepts pipeline input and remaining
    arguments.

  .PARAMETER ToWindows
    Convert forward slashes to backslashes instead (Unix -> Windows).

  .PARAMETER DriveStyle
    Convert a leading Windows drive (e.g. 'C:\') to MSYS form ('/c/').

  .PARAMETER NoLeadingSlash
    Skip prepending the leading '/' in the default (forward) direction.

  .EXAMPLE
    Convert-PathSlash 'C:\Users\me\file.txt'
    # -> /C:/Users/me/file.txt      (default: backslash->slash, leading slash)

  .EXAMPLE
    Convert-PathSlash -DriveStyle 'C:\Users\me'
    # -> /c/Users/me                (MSYS/Git-Bash drive style)

  .EXAMPLE
    Convert-PathSlash -ToWindows '/c/Users/me'
    # -> c:\Users\me

  .EXAMPLE
    'src/app', 'bin/tool' | Convert-PathSlash -ToWindows -NoLeadingSlash
    # pipe several paths through at once

  .EXAMPLE
    slashf 'C:\temp\x'            # short alias for the default behavior
  #>
  [CmdletBinding()]
  [OutputType([string])]
  [Alias('slashf')]
  param(
    [Parameter(Position = 0, ValueFromPipeline, ValueFromRemainingArguments)]
    [string[]]$Path,

    [switch]$ToWindows,
    [switch]$DriveStyle,
    [switch]$NoLeadingSlash
  )

  process {
    # Join remaining args into one string (zsh `${*}` behavior). When the input
    # arrives via the pipeline, each item comes through process individually.
    if (-not $Path) { return }
    $s = $Path -join ' '

    if ($ToWindows) {
      # Unix -> Windows. Preserve a leading '//' (UNC) as '\\'.
      $unc = $s -match '^(//|\\\\)'
      $out = $s -replace '/', '\'
      # Collapse duplicate backslashes...
      $out = $out -replace '\\{2,}', '\'
      # ...then restore the UNC prefix if there was one.
      if ($unc) { $out = '\' + $out }
      # '/c/foo' style -> 'c:\foo' if it looks like a drive.
      $out = $out -replace '^\\([A-Za-z])\\', '$1:\'
      return $out
    }

    # Default / -DriveStyle: Windows -> Unix (backslash -> forward slash).
    $out = $s -replace '\\', '/'
    # Collapse duplicate forward slashes (keep it simple; UNC becomes single).
    $out = $out -replace '/{2,}', '/'

    if ($DriveStyle) {
      # 'C:/Users' -> '/c/Users'  (drive letter lowercased, ':' removed).
      if ($out -match '^([A-Za-z]):/?(.*)$') {
        $drive = $Matches[1].ToLower()
        $rest  = $Matches[2]
        return "/$drive/$rest" -replace '/{2,}', '/'
      }
    }

    if (-not $NoLeadingSlash -and $out -notmatch '^/') {
      $out = '/' + $out
    }
    $out
  }
}
