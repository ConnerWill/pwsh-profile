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
├── install.ps1                  # one-time module installer (run manually)
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

## Setup on a new machine

1. Place this directory at `C:\Users\<you>\Documents\PowerShell\`.
2. Install the expected modules (one-time):
   ```powershell
   pwsh -NoProfile -File "$HOME\Documents\PowerShell\install.ps1"
   ```
3. Open a new PowerShell 7 session (or run `reload`).

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
