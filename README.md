<div align="center">

# POWERSHELL PROFILE

> *A modular PowerShell 7 profile and configuration.*

</div>

---

## Contents

- [Overview](#overview)
- [Installation](#installation)
  - [Quick bootstrap (one-liner)](#quick-bootstrap-one-liner)
  - [Manual](#manual)
  - [Try it in Docker (throwaway)](#try-it-in-docker-throwaway)
  - [Personal / machine-local overrides](#personal--machine-local-overrides)
  - [Updating](#updating)
- [Layout](#layout)
- [Load order](#load-order)
- [The prompt](#the-prompt)
- [Functions](#functions)
  - [Filesystem / navigation](#filesystem--navigation)
  - [Command / introspection](#command--introspection)
  - [Color / ANSI](#color--ansi)
  - [Package / module search](#package--module-search)
  - [System / admin](#system--admin)
  - [Active Directory](#active-directory)
  - [Host / system info](#host--system-info)
  - [Misc](#misc)
- [Line endings (CRLF)](#line-endings-crlf)
- [Editing tips](#editing-tips)

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

### Try it in Docker (throwaway)

Spin up a disposable PowerShell 7 container, install `git`, run the bootstrap
installer, then drop into a fresh `pwsh` session with the profile loaded:

```bash
docker run -it --rm mcr.microsoft.com/powershell:latest bash -c "apt-get update -qq && apt-get install -y -qq git && pwsh -NoProfile -c 'Invoke-RestMethod https://raw.githubusercontent.com/ConnerWill/pwsh-profile/main/install-pwshprofile.ps1 | Invoke-Expression' && exec pwsh"
```

> The base image has no `git`, so it is installed first (the image is
> Ubuntu-based). The installer clones into the container's profile directory
> (`~/.config/powershell` on Linux) and installs modules. Nothing on your host
> is touched — the container is removed on exit (`--rm`).

### (Optional) Allow local script execution

If the profile is blocked from running:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Start a new PowerShell 7 session

Open a new `pwsh` window (or run `reload` / `ez` in an existing one). You should see
the module-load line, a random ASCII banner, and the git-aware prompt.

### Personal / machine-local overrides

Anything private or machine-specific goes in `powershell-config.ps1` in the
profile directory. It is **gitignored** and dot-sourced early at startup, so it
never ends up in the repo. Use it to set custom variables — for example, your
preferred editor:

```powershell
# powershell-config.ps1

# Pick your editor (used by the `e` function): vim, nvim, code, notepad++, ...
$EDITOR = 'code'

# Turn the startup ASCII banner on or off.
$ShowStartupArt = $true
```

### Updating

```powershell
cd "$HOME\Documents\PowerShell"
git pull
reload   # or 'ez', or open a new shell
```

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
├── pwsh.d/                      # auto-loaded config fragments (in filename order)
│   ├── 01_variables.ps1         # environment variables (XDG paths, EDITOR, HISTFILE, ...)
│   ├── 02_preferences.ps1       # shell preferences (UTF-8, ConciseView, telemetry opt-out)
│   ├── 06_modules.ps1           # ensure optional modules (idempotent)
│   ├── 10_ascii_art.ps1         # source ascii-art.ps1; random startup banner
│   ├── 20_functions.ps1         # loader: dot-sources every pwsh.d/functions/*.ps1
│   ├── 26_completion.ps1        # tab-completion integrations (Chocolatey)
│   ├── 30_psreadline.ps1        # PSReadLine OPTIONS: vi edit mode, prediction, history path
│   ├── 40_prompt.ps1            # prompt() + git status segment
│   ├── 50_keybindings.ps1       # PSReadLine KEY BINDINGS (Set-PSReadLineKeyHandler)
│   └── functions/               # one file per function (see Functions section below)
├── local-modules/               # vendored modules loaded by path at startup
└── Modules/                     # installed modules (PowerShellGet)
```

> **Adding a function:** drop a `<Name>.ps1` into `pwsh.d/functions/`. The
> `20_functions.ps1` loader sources every file there in sorted order, so it is
> picked up automatically — no need to edit the loader. Inline `Set-Alias`
> trailers live in the same file as their function.


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

## Functions

Functions live in `pwsh.d/functions/` — one file per function, loaded by
`20_functions.ps1`. Add one by dropping a `<Name>.ps1` into that directory.
Aliases are shown in parentheses.

### Filesystem / navigation

| Function           | Description                                             |
| ------------------ | ------------------------------------------------------- |
| `l` / `ll` / `sl`  | Directory listings (colored via `Get-ChildItemColor`, with plain fallback) |
| `cdp`              | `cd` to the profile directory                           |
| `touch <name>`     | Create an empty file (like `touch` in Linux)            |
| `e [path]`         | Open `$EDITOR`; with no path, opens the editor empty    |
| `Search-Item` (`search`) | Recursive filename search from the current directory |

### Command / introspection

| Function              | Description                                          |
| --------------------- | ---------------------------------------------------- |
| `which <cmd>`         | Resolve a command — alias, function, cmdlet, or application (like `which`) |
| `Get-Syntax` (`synt`, `syntax`) | Show a command's syntax                    |
| `Get-CommandInfo`     | Return the `CommandInfo` for a command               |
| `Get-CmdletAlias` (`aliases`) | List the aliases of a cmdlet                 |
| `Test-Command` (`tcm`) | Check whether a command exists                      |
| `Encode-Command`      | Base64-encode a command for `pwsh -EncodedCommand`   |

### Color / ANSI

| Function                | Description                                        |
| ----------------------- | -------------------------------------------------- |
| `Get-ANSIColors`        | Print the 256-color ANSI palette                   |
| `Show-ColorTable`       | Print a foreground/background console-color table  |
| `Show-ColorList`        | List console colors with their indices             |
| `Show-ANSISequence`     | Display ANSI escape sequences (basic/fore/back/RGB)|
| `New-ANSIBar`           | Build a colored bar from a range of 256-colors     |
| `draw_line`             | Draw a single full-width line in a given color (default green) |
| `New-RedGreenGradient`  | Render a red→green gradient bar                     |
| `Convert-HexToAnsi` (`cha`) | Convert an HTML hex color to an ANSI sequence  |
| `Out-ConditionalColor` (`occ`) | Color pipeline objects by a condition       |
| `Blink-Message`         | Print blinking colored text                        |

### Package / module search

| Function          | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `Find-Package` (`fpkg`) | Search packages: `-Source Module` (default) / `Script` / `Choco` |
| `Install-PSModule` (`ipsmod`) | Install (CurrentUser) + import a module, then list its commands |

> Replaces the older `Search-Modules` / `Search-Script` / `Search-Choco` /
> `yays` / `Instort-Module` helpers. The old names (except `yays`) remain as
> aliases, so `Search-Modules` etc. still work.

### System / admin

| Function                  | Description                                     |
| ------------------------- | ----------------------------------------------- |
| `Reload-Profile` (`reload`, `ez`) | Re-source the profile in the current session |
| `Start_PSTranscript`      | Start a session transcript (auto-run; prunes old logs) |
| `ssh-local`               | SSH helper: `ssh-local -User <u> -Hostname <h> -Port <p>` |
| `Get-WiFiPasswords`       | List saved Wi-Fi networks + passwords as a table |
| `Update-Windows`          | Download and install Windows updates            |

### Active Directory

> Requires the `ActiveDirectory` module (RSAT). Each function fails gracefully
> with a clear error if the module or lookup is unavailable.
>
> **Run as a specific user / DC:** every function accepts `-Credential` and
> `-Server`, passed through to the AD cmdlets — you don't need to be logged in
> as that user. Example:
> `Get-AdUserInfo jdoe -Credential (Get-Credential) -Server dc01`

| Function                   | Description                                     |
| -------------------------- | ----------------------------------------------- |
| `Get-UserAdGroupMembership`| List the AD groups a user (or users) belongs to |
| `Get-AdUserInfo`           | Show common AD attributes for a user            |
| `Get-AdGroupMembers`       | List members of an AD group (`-Recursive` for nested) |
| `Get-LockedAdUsers`        | Find accounts that are currently locked out     |

### Host / system info

| Function                   | Description                                    |
| -------------------------- | ---------------------------------------------- |
| `Get-PSWho` (`pswho`)      | Summary of user, elevation, OS, and PowerShell |
| `Get-WindowsVersion` (`wver`) | Detailed Windows version/build info         |
| `Get-WindowsVersionString` | One-line Windows version string                |

### Misc

| Function          | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `Motd-AsciiArt`   | Print the startup ASCII banner (when `$ShowStartupArt`) |
| `Invoke-BeepMusic` (`beepmusic`) | Play random beeps through the console speaker (Windows; `-Infinite` to loop) |
| `Get-PwSHKeybindings` | List all PSReadLine key handlers (defined in `50_keybindings.ps1`) |

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
- After edits, run `reload` (or `ez`) to apply without opening a new shell.
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
