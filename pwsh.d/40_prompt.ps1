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
## Composed entirely from the shared $Colors hashtable defined in profile.ps1
## (single source of truth). The hues the prompt needs all have named entries
## in $Colors: CyanBright (51), Teal (66), Grey (8), Violet (99).
##
## Reminder on the sequences: `e[0m = reset, `e[1m = bold, `e[38;5;Nm = 256-color
## foreground. A compound like `e[0;1;38;5;51m is reset+bold+color in one escape;
## here we build the equivalent by concatenating $Colors.Reset + $Colors.Bold + hue.
## ---------------------------------------------------------------------------

$PromptColors = @{
  Reset     = $($Colors.Reset)
  Admin     = "$($Colors.Reset)$($Colors.Bold)$($Colors.Underline)$($Colors.Blink)$($Colors.Red)"   # bold+underline+blink red - [ADMIN]
  Date      = "$($Colors.Reset)$($Colors.Bold)$($Colors.Grey)"           # bold grey   - timestamp
  Bracket   = "$($Colors.Reset)$($Colors.Bold)$($Colors.CyanBright)"    # bold cyan   - [ ] user/host/path brackets (zsh %F{51})
  Glyph     = "$($Colors.Reset)$($Colors.Bold)$($Colors.Blue)"           # blue        - pwsh glyph
  UserName  = "$($Colors.Reset)$($Colors.Violet)"                      # violet      - username (zsh %F{99})
  AtSymbol  = "$($Colors.Reset)$($Colors.Magenta)"                     # magenta     - user/host separator (zsh %F{201})
  HostName  = "$($Colors.Reset)$($Colors.Violet)"                      # violet      - hostname (zsh %F{99})
  Path      = "$($Colors.Reset)$($Colors.Teal)"                        # teal        - current directory (zsh %F{66})
  GitClean  = "$($Colors.Reset)$($Colors.Bold)$($Colors.Green)"          # bold green  - clean branch / ⊕ added count
  GitDirty  = "$($Colors.Reset)$($Colors.Bold)$($Colors.Yellow)"         # bold yellow - dirty branch (tracked changes only)
  GitUntrk  = "$($Colors.Reset)$($Colors.Bold)$($Colors.Red)"            # bold red    - untracked files present
  GitConf   = "$($Colors.Reset)$($Colors.Bold)$($Colors.Orange)"         # bold orange - merge conflicts
}

Function Get-GitPromptSegment {
  <#
    Builds a zsh-style git segment:  :(repo)-[branch⊕N⊝N⊛N]
      ⊕N = staged / modified   ⊝N = deleted   ⊛N = untracked
    Branch color by priority: conflict(orange) > untracked(red) > dirty(yellow) > clean(green).
    Returns an empty string when not inside a git work tree.

    Performance: uses a SINGLE `git status --porcelain=v2 --branch` call for the
    in-repo check, branch name, AND file states (plus one cheap --show-toplevel
    for the repo name). This keeps the prompt fast -- the old version spawned
    four git processes on every render.
  #>

  if (-not (Get-Command git -ErrorAction Ignore)) { return "" }

  # One call: branch header + per-file status. Non-zero exit => not a repo.
  $status = git status --porcelain=v2 --branch 2>$null
  if ($LASTEXITCODE -ne 0) { return "" }

  $branch    = $null
  $added     = 0
  $deleted   = 0
  $untracked = 0
  $conflict  = 0

  foreach ($line in $status) {
    if (-not $line) { continue }

    # Header lines start with '# '. Capture the branch name.
    if ($line.StartsWith('# branch.head ')) { $branch = $line.Substring(14).Trim(); continue }
    if ($line.StartsWith('#')) { continue }

    # Entry lines are keyed by their first token: 1/2 = changed, u = unmerged,
    # ? = untracked. (Use literal checks -- NOT -Wildcard, where '?' is a
    # single-char wildcard and would match the '#' header lines.)
    $kind = $line[0]
    switch ($kind) {
      '?' { $untracked++; continue }
      'u' { $conflict++;  continue }
      '2' { $added++;     continue }   # renamed/copied
      '1' {
        # "1 <XY> ..." : X = staged (index), Y = worktree. '.' means unchanged.
        $x = $line[2]; $y = $line[3]
        if     ($x -eq 'D' -or $y -eq 'D') { $deleted++ }
        elseif ($x -ne '.' -or $y -ne '.') { $added++ }
        continue
      }
    }
  }

  if (-not $branch -or $branch -eq '(detached)') {
    # Detached HEAD: show short oid from the branch.oid header if present.
    $oidLine = $status | Where-Object { $_ -like '# branch.oid *' } | Select-Object -First 1
    if ($oidLine) { $branch = $oidLine.Substring(13).Trim().Substring(0,7) } else { $branch = '?' }
  }

  # Repo name = basename of the work-tree root (one more lightweight call).
  $top  = git rev-parse --show-toplevel 2>$null
  $repo = if ($top) { Split-Path -Leaf $top } else { '' }

  if     ($conflict  -gt 0)          { $gitColor = $PromptColors.GitConf  }  # orange
  elseif ($untracked -gt 0)          { $gitColor = $PromptColors.GitUntrk }  # red
  elseif (($added + $deleted) -gt 0) { $gitColor = $PromptColors.GitDirty }  # yellow
  else                               { $gitColor = $PromptColors.GitClean }  # green

  $reset = $PromptColors.Reset
  # zsh VCS scheme: ':' and '-' separators yellow (190), parens/brackets
  # magenta (201), repo name white (15), branch color by state.
  $sep   = "$($Colors.Reset)$($Colors.Yellow)"
  $paren = "$($Colors.Reset)$($Colors.Magenta)"
  $repoc = "$($Colors.Reset)$($Colors.White)"

  # Counters (fixed per-kind colors): ⊕ staged/modified, ⊝ deleted, ⊛ untracked.
  $counts = ""
  if ($added     -gt 0) { $counts += "$($Colors.Bold)$($Colors.Green)⊕${added}${reset}" }
  if ($deleted   -gt 0) { $counts += "$($Colors.Bold)$($Colors.Yellow)⊝${deleted}${reset}" }
  if ($untracked -gt 0) { $counts += "$($Colors.Bold)$($Colors.Red)⊛${untracked}${reset}" }

  # :(repo)-[branch⊕N⊝N⊛N]   -- :/- yellow, () magenta, repo white, [] magenta
  return "${sep}:${paren}(${repoc}${repo}${paren})${sep}-${paren}[${gitColor}${branch}${counts}${paren}]${reset}"
}

Function prompt {
  $c = $PromptColors

  # User/host: prefer Windows vars, fall back to Linux ($USER / hostname) so the
  # prompt is correct cross-platform (and in containers).
  # User/host. Override by setting $PROMPT_USERNAME / $PROMPT_HOSTNAME in
  # powershell-config.ps1; otherwise auto-detect via env vars / .NET APIs
  # (which handle containers / non-login shells where env vars are unset).
  $PromptUserName = if ($PROMPT_USERNAME) { $PROMPT_USERNAME }
                    elseif ($env:USERNAME) { $env:USERNAME }
                    elseif ($env:USER)     { $env:USER }
                    else { [System.Environment]::UserName }
  $PromptHostName = if ($PROMPT_HOSTNAME) { $PROMPT_HOSTNAME }
                    elseif ($env:COMPUTERNAME) { $env:COMPUTERNAME }
                    else { [System.Environment]::MachineName }
  # Current directory, with the home dir collapsed to '~' (like zsh/bash).
  $PromptPWD = "$PWD"
  $homeDir = $HOME.TrimEnd('\','/')
  if ($homeDir -and ($PromptPWD -eq $homeDir)) {
    $PromptPWD = '~'
  }
  elseif ($homeDir -and $PromptPWD.StartsWith($homeDir + [IO.Path]::DirectorySeparatorChar)) {
    $PromptPWD = '~' + $PromptPWD.Substring($homeDir.Length)
  }
  $PromptDate        = "($(Get-Date -UFormat '%Y-%m-%d %H:%M:%S'))"
  $PromptRandomColor = Get-Random -Min 1 -Max 255
  # Prompt segment toggles.
  #   Hostname: shown if $PROMPT_SHOW_HOSTNAME is explicitly set; otherwise
  #   auto-shown when $PROMPT_HOSTNAME is set (so setting the name is enough);
  #   else hidden by default.
  #   Date: off unless $PROMPT_SHOW_DATE is set.
  $UsePromptUserName = $True
  $UsePromptPWD      = $True
  $UsePromptHostName = if ($null -ne $PROMPT_SHOW_HOSTNAME) { [bool]$PROMPT_SHOW_HOSTNAME }
                       elseif ($PROMPT_HOSTNAME)            { $True }
                       else                                 { $False }
  $UsePromptDate     = if ($null -ne $PROMPT_SHOW_DATE)     { [bool]$PROMPT_SHOW_DATE } else { $False }
  $PromptAtSymbol             = "@";  $PromptSymbol             = ": "
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

  # The pwsh glyph before the username. Toggle with $PROMPT_SHOW_GLYPH in
  # powershell-config.ps1 (set $false if your terminal font lacks the glyph).
  $showGlyph = if ($null -ne $PROMPT_SHOW_GLYPH) { [bool]$PROMPT_SHOW_GLYPH } else { $true }
  $GlyphSeg = if ($showGlyph) { "$($c.Glyph)󰨊 " } else { "" }

  # [ADMIN](date)[user host][path]:(repo)-[branch...]:   -- colors from $PromptColors
  $Prompt =
    "$($c.Admin)${AdminPrompt}" +
    "$($c.Date)${PromptDate}" +
    "$($c.Bracket)${PromptUserHostStartBracket}" +
    "${GlyphSeg}" +
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
