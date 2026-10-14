###{{{ PROMPT
## Interactive prompt + git status segment.
## Loaded from profile.ps1 via the pwsh.d loader (dot-sourced into global scope),
## so the `prompt` function defined here becomes the session prompt.
##
## Git segment mirrors the zsh prompt style:
##   [host][path]:(repo)-[branch⊕N⊝N]:
## where ⊕N = staged/added entries, ⊝N = deleted entries, and the branch
## color reflects repo state (green=clean, yellow=dirty, red=conflicts).

## ---------------------------------------------------------------------------
## Prompt color palette.
## Composed entirely from the shared $color_* variables defined in profile.ps1
## (single source of truth). The hues the prompt needs all have named entries
## in the main color array: $color_cyan_bright (51), $color_teal (66),
## $color_grey (8), $color_violet (99).
##
## Reminder on the sequences: `e[0m = reset, `e[1m = bold, `e[38;5;Nm = 256-color
## foreground. A compound like `e[0;1;38;5;51m is reset+bold+color in one escape;
## here we build the equivalent by concatenating $color_reset + $color_bold + hue.
## ---------------------------------------------------------------------------

$PromptColors = @{
  Reset     = ${color_reset}
  Admin     = "${color_reset}${color_bold}${color_red}"            # bold red    - [ADMIN]
  Date      = "${color_reset}${color_bold}${color_grey}"           # bold grey   - timestamp
  Bracket   = "${color_reset}${color_violet}"                      # violet      - [ ] ( ) delimiters
  UserName  = "${color_reset}${color_bold}${color_cyan_bright}"    # bold cyan   - username
  AtSymbol  = "${color_reset}${color_blue}"                        # blue        - user/host separator
  HostName  = "${color_reset}${color_cyan_bright}"                 # cyan        - hostname
  Path      = "${color_reset}${color_teal}"                        # teal        - current directory
  GitClean  = "${color_reset}${color_bold}${color_green}"          # bold green  - clean branch / ⊕ added count
  GitDirty  = "${color_reset}${color_bold}${color_yellow}"         # bold yellow - dirty branch (tracked changes only)
  GitUntrk  = "${color_reset}${color_bold}${color_red}"            # bold red    - untracked files present
  GitConf   = "${color_reset}${color_bold}${color_orange}"         # bold orange - merge conflicts
}

Function Get-GitPromptSegment {
  <#
    Builds a zsh-style git segment:  :(repo)-[branch⊕N⊝N]
      ⊕N = staged / added entries, ⊝N = deleted entries
    Color reflects repo state:
      clean      -> green  ($PromptColors.GitClean)
      dirty      -> yellow ($PromptColors.GitDirty)
      conflicts  -> red    ($PromptColors.GitConf)
    Returns an empty string when not inside a git work tree.
  #>

  # Fast bail-out if git isn't available.
  if (-not (Get-Command git -ErrorAction Ignore)) { return "" }

  # Are we inside a work tree? (silence stderr; check exit code)
  $inside = (git rev-parse --is-inside-work-tree 2>$null)
  if ($LASTEXITCODE -ne 0 -or $inside -ne 'true') { return "" }

  # Repo name = basename of the toplevel directory.
  $top = (git rev-parse --show-toplevel 2>$null)
  $repo = if ($top) { Split-Path -Leaf $top } else { "" }

  # Branch (or short SHA when detached).
  $branch = (git symbolic-ref --short -q HEAD 2>$null)
  if (-not $branch) { $branch = (git rev-parse --short HEAD 2>$null) }
  if (-not $branch) { $branch = "?" }

  # Porcelain status -> count staged/modified (added), deleted, and untracked.
  $added     = 0
  $deleted   = 0
  $untracked = 0
  $conflict  = 0
  foreach ($line in (git status --porcelain 2>$null)) {
    if ($line.Length -lt 2) { continue }
    $x = $line[0]   # staged (index) status
    $y = $line[1]   # worktree status
    # Untracked files are reported as '??'.
    if ($x -eq '?' -and $y -eq '?') { $untracked++; continue }
    # Merge conflicts: any 'U', or AA / DD.
    if ($x -eq 'U' -or $y -eq 'U' -or ($x -eq 'A' -and $y -eq 'A') -or ($x -eq 'D' -and $y -eq 'D')) {
      $conflict++
      continue
    }
    if ($x -eq 'A' -or $x -eq 'M' -or $x -eq 'R' -or $x -eq 'C' -or $y -eq 'M' -or $y -eq 'A') { $added++ }
    if ($x -eq 'D' -or $y -eq 'D') { $deleted++ }
  }

  # Choose branch color by priority: conflict > untracked > tracked-dirty > clean.
  if     ($conflict  -gt 0)              { $gitColor = $PromptColors.GitConf  }  # orange
  elseif ($untracked -gt 0)              { $gitColor = $PromptColors.GitUntrk }  # red
  elseif (($added + $deleted) -gt 0)     { $gitColor = $PromptColors.GitDirty }  # yellow
  else                                   { $gitColor = $PromptColors.GitClean }  # green

  $reset = $PromptColors.Reset
  $paren = $PromptColors.Bracket

  # Build counters only when non-zero, mirroring the zsh glyph style.
  #   ⊕N = staged/modified (green)   ⊝N = deleted (yellow)   ⊛N = untracked (red)
  # Counter colors are fixed per-kind and independent of the branch-state color.
  $counts = ""
  if ($added     -gt 0) { $counts += "${color_bold}${color_green}⊕${added}${reset}" }
  if ($deleted   -gt 0) { $counts += "${color_bold}${color_yellow}⊝${deleted}${reset}" }
  if ($untracked -gt 0) { $counts += "${color_bold}${color_red}⊛${untracked}${reset}" }

  # :(repo)-[branch⊕N⊝N⊛N]
  return "${paren}:($repo)-[${gitColor}${branch}${counts}${paren}]${reset}"
}

Function prompt {
  $c = $PromptColors

  $PromptUserName    = "$env:USERNAME"
  $PromptHostName    = "$env:COMPUTERNAME"
  $PromptPWD         = "$PWD"
  $PromptDate        = "($(Get-Date -UFormat '%Y-%m-%d %H:%M:%S'))"
  $PromptRandomColor = Get-Random -Min 1 -Max 255
  $UsePromptUserName          = $True; $UsePromptHostName        = $False
  $UsePromptPWD               = $True; $UsePromptDate            = $False
  $PromptAtSymbol             = " ";  $PromptSymbol             = ": "
  $PromptUserHostStartBracket = "[";   $PromptUserHostEndBracket = "]"
  $PromptPathStartBracket     = "[";   $PromptPathEndBracket     = "]"
  $AdminPromptTag             = "[ADMIN]"

  ## Admin detection reuses the is_admin helper defined in profile.ps1.
  If (is_admin)                                     { $AdminPrompt = $AdminPromptTag   }
  If (!($UsePromptUserName))                        { $PromptUserName             = "" }
  If (!($UsePromptHostName))                        { $PromptHostName             = "" }
  If (!($UsePromptDate))                            { $PromptDate                 = "" }
  If (!($PromptSymbol))                             { $PromptSymbol               = "" }
  If (!($UsePromptUserName -and $UsePromptHostName)){ $PromptAtSymbol             = "" }
  If (!($UsePromptUserName -or $UsePromptHostName)) { $PromptUserHostStartBracket = ""
                                                      $PromptUserHostEndBracket   = "" }
  If (!($UsePromptPWD))                             { $PromptPWD                  = ""
                                                      $PromptPathStartBracket     = ""
                                                      $PromptPathEndBracket       = "" }

  $PromptGit = Get-GitPromptSegment

  # [ADMIN](date)[user host][path]:(repo)-[branch...]:   -- colors from $PromptColors
  $Prompt =
    "$($c.Admin)${AdminPrompt}" +
    "$($c.Date)${PromptDate}" +
    "$($c.Bracket)${PromptUserHostStartBracket}" +
    "$($c.UserName)${PromptUserName}" +
    "$($c.AtSymbol)${PromptAtSymbol}" +
    "$($c.HostName)${PromptHostName}" +
    "$($c.Bracket)${PromptUserHostEndBracket}" +
    "$($c.Bracket)${PromptPathStartBracket}" +
    "$($c.Path)${PromptPWD}" +
    "$($c.Bracket)${PromptPathEndBracket}" +
    "${PromptGit}" +
    "`e[0;38;5;${PromptRandomColor}m${PromptSymbol}" +   # random-color end symbol (intentionally dynamic)
    "$($c.Reset)"
  $Prompt
}
###}}} END PROMPT
