<div align="center">

# POWERSHELL PROFILE

> *A modular PowerShell 7 profile and configuration.*

</div>

---

## Overview

This is a **PowerShell 7** (`pwsh`) profile organized as a small bootstrap
(`profile.ps1`) plus a directory of focused configuration fragments
(`pwsh.d/`) that are loaded in order on every startup.

- `profile.ps1` is the `CurrentUserAllHosts` profile. It sets up core
  variables, the color palette, message helpers, loads modules, then
  dot-sources every `*.ps1` in `pwsh.d/` **in filename order**.
- `pwsh.d/` holds the actual behavior (functions, prompt, PSReadLine options,
  keybindings), split by domain so each piece is easy to find and edit.

The numeric filename prefixes control load order.

---

## Layout

```
Documents/PowerShell/
├── profile.ps1                  # bootstrap: variables, colors, module load, pwsh.d loader
├── Microsoft.PowerShell_profile.ps1  # CurrentUserCurrentHost (intentionally empty)
├── powershell-config.ps1        # optional local overrides, dot-sourced early (may be empty)
├── install-pwshprofile.ps1       # bootstrap: clone repo + install modules (run manually)
├── ascii-art.ps1                # ASCII art banners ($GRIMREAPER), sourced on demand
├── README.md
├── pwsh.d/                      # auto-loaded config fragments (in order)
│   ├── 02_preferences.ps1       # $PSDefaultParameterValues / preference notes
│   ├── 06_modules.ps1           # ensure optional modules (idempotent)
│   ├── 20_functions_fs.ps1      # filesystem / navigation: l, ll, sl, touch, cdp, e, Search-Item
│   ├── 21_functions_cmd.ps1     # command/introspection: which, Get-Syntax, Test-Command, ...
│   ├── 22_functions_ansi.ps1    # ANSI/color utilities and demos
│   ├── 23_functions_pkg.ps1     # package/module search: yays, Search-Modules, Search-Choco, ...
│   ├── 24_functions_system.ps1  # system/admin: transcript, ssh helpers, Update-Windows, Reload-Profile
│   ├── 30_psreadline.ps1        # PSReadLine OPTIONS: vi edit mode, prediction, history path, vi cursor
│   ├── 40_prompt.ps1            # prompt() + git status segment
│   └── 50_keybindings.ps1       # PSReadLine KEY BINDINGS (Set-PSReadLineKeyHandler)
├── local-modules/               # vendored modules loaded by path at startup
└── Modules/                     # installed modules (PowerShellGet)
```

> **Options vs. keybindings:** PSReadLine *options/preferences* (edit mode,
> prediction, history path, cursor) live in `30_psreadline.ps1`. Actual key
> *bindings* live in `50_keybindings.ps1`. `30` loads before `50` so the edit
> mode is set before handlers register.

---

## Load order

1. `profile.ps1`
   - Core variables (`$PDOTDIR`, `$PDOTDDIR`, `$EDITOR`, `$HISTFILE`, XDG paths, ...)
   - `read_config` dot-sources `powershell-config.ps1` if present
   - Color palette (`$color_*`, `$bg_color_*`) — single source of truth for colors
   - Message helpers (`error`, `warn`, `info`, `debug`, `success`, `is_admin`)
   - Module loading (`Get-ChildItemColor`, `PSReadLine`, local-modules)
   - **pwsh.d loader** — dot-sources every `pwsh.d/*.ps1` sorted by name
2. `pwsh.d/*.ps1` fragments (02 → 06 → 20..24 → 30 → 40 → 50)
3. `Microsoft.PowerShell_profile.ps1` (CurrentUserCurrentHost; empty)

---

## The prompt

Defined in `pwsh.d/40_prompt.ps1`. Format:

```
[ADMIN](date)[user host][path]:(repo)-[branch⊕N⊝N⊛N]:
```

- `[user host][path]` — user/host and current directory.
- `:(repo)-[branch...]` — git segment (only inside a repo).

### Git status colors

| State              | Branch color | Notes                                   |
|--------------------|--------------|-----------------------------------------|
| Clean              | green        | no changes                              |
| Dirty (tracked)    | yellow       | staged/modified/deleted, nothing new    |
| Untracked present  | red          | one or more `??` files                  |
| Merge conflict     | orange (208) | highest priority                        |

### Git count glyphs

| Glyph | Meaning            | Color  |
|-------|--------------------|--------|
| `⊕N`  | staged / modified  | green  |
| `⊝N`  | deleted            | yellow |
| `⊛N`  | untracked          | red    |

All prompt colors are composed from the named `$color_*` variables defined in
`profile.ps1`.

---

## Handy commands

| Command / alias        | Does                                                 |
|------------------------|------------------------------------------------------|
| `l`, `ll`, `sl`        | directory listings (colored via Get-ChildItemColor)  |
| `touch <name>`         | create an empty file                                 |
| `cdp`                  | cd to the profile directory                          |
| `e [path]`             | open `$EDITOR` (notepad++); no path = open empty     |
| `which <name>`         | show a function's ScriptBlock                         |
| `Get-Syntax` / `synt`  | show a command's syntax                              |
| `search` (Search-Item) | recursive filename search                            |
| `Reload-Profile` / `reload` / `src` | re-source the profile in place          |
| `Get-PwSHKeybindings`  | list PSReadLine key handlers                         |

---

## Installation

PowerShell 7 loads this from your `Documents\PowerShell` directory. `install-pwshprofile.ps1`
clones the repo there (backing up any existing profile) and installs the
required modules.

### Quick bootstrap (one-liner)

Run this in **PowerShell 7** — no manual clone needed. It downloads and runs
`install-pwshprofile.ps1`, which clones the repo to your profile directory and installs the
modules:

```powershell
Invoke-RestMethod https://raw.githubusercontent.com/ConnerWill/pwsh-profile/main/install-pwshprofile.ps1 | Invoke-Expression
```

> `git` must be installed and on PATH for the clone step. When piped to
> `Invoke-Expression` the script runs with its defaults (you can't pass
> parameters through the pipe — use the manual method below if you need
> `-Force`/`-SkipClone`).

### Manual

```powershell
# Download then run (lets you pass parameters)
$url = 'https://raw.githubusercontent.com/ConnerWill/pwsh-profile/main/install-pwshprofile.ps1'
Invoke-RestMethod $url -OutFile "$env:TEMP\pwsh-profile-install.ps1"
pwsh -NoProfile -File "$env:TEMP\pwsh-profile-install.ps1"      # add -Force to reinstall modules
```

Or clone yourself and run the in-repo installer (it detects the existing clone
and just updates + installs modules):

```powershell
git clone https://github.com/ConnerWill/pwsh-profile.git (Split-Path $PROFILE.CurrentUserAllHosts)
pwsh -NoProfile -File "$(Split-Path $PROFILE.CurrentUserAllHosts)\install-pwshprofile.ps1"
```

Modules installed (CurrentUser scope, idempotent): `Get-ChildItemColor`,
`PSReadLine`, `posh-git`, `Plaster`, `PSFunctionTools`.

### (Optional) Allow local script execution

If the profile is blocked from running:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Start a new PowerShell 7 session

Open a new `pwsh` window (or run `reload` in an existing one). You should see
the module-load line, a random ASCII banner, and the git-aware prompt.

### Personal / machine-local overrides

Anything private or machine-specific goes in `powershell-config.ps1` in the
profile directory. It is **gitignored** and dot-sourced early at startup, so it
never ends up in the repo. Example:

```powershell
# powershell-config.ps1
function ssh-local-vm { ssh-local -User me -Hostname localhost -Port 2222 }
$EDITOR = 'code'
```

### Updating

```powershell
cd "$HOME\Documents\PowerShell"
git pull
reload   # or open a new shell
```

---

## Line endings (CRLF)

PowerShell on Windows expects CRLF. A `.gitattributes` enforces this for
`*.ps1` so cloning on different machines doesn't introduce `^M`/LF-mixing
problems. If you ever see stray `^M`, convert a file to CRLF:

```powershell
(Get-Content -Raw file.ps1) -replace "`r?`n","`r`n" | Set-Content -NoNewline file.ps1
```

---

## Editing tips

- Add a new function group as `pwsh.d/NN_<name>.ps1`; it loads automatically.
- Keep anything that must exist before fragments (e.g. `$PDOTDDIR`, the color
  palette) in `profile.ps1`.
- After edits, run `reload` to apply without opening a new shell.
- Validate a fragment parses:
  ```powershell
  $e=$null; [System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path .\pwsh.d\40_prompt.ps1), [ref]$null, [ref]$e); $e
  ```

---

## Author

Repository
: [pwsh-profile](https://github.com/ConnerWill/pwsh-profile)

Author
: `Conner Will`

Website
: [connerwill.com](https://connerwill.com)

GitHub
: [github/ConnerWill](https://github.com/ConnerWill)

---
