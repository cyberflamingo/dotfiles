# Dotfiles cleanup and chezmoi migration

Date: 2026-10-22
Branch: `chezmoi-migration`

## Goals

- Replace dotbot and its submodules with chezmoi.
- Keep work-specific values (identity, internal URLs, tokens) out of this public repo.
- Support only the systems in use today, with OS and WSL differences expressed as templates.
- Bring stale configs up to date or delete them.

## Scope

In scope: WSL2 (work laptop), personal Linux desktop, Windows (work laptop).

Also in scope: the Turris OS router (OpenWrt-based), reached over SSH, and privoxy, dnsmasq and dnscrypt-proxy on the personal Linux desktop.

Dropped: macOS, Kali and server (`bootstrap/macOS`, `meta/configs/{mac,kali,server}`, the `.macos` config variants).

Known gaps in what stays: dnsmasq only exists as a macOS variant and needs a Linux version; the dnscrypt `blocklists.txt` that the old install copied was deleted from the repo in 2022 and needs a replacement.

## Machine model

Profile is detected, not chosen:

| Profile | Detection |
|---|---|
| WSL | `.chezmoi.kernel.osrelease` contains "microsoft" |
| Windows | `.chezmoi.os == "windows"` |
| Linux desktop | `.chezmoi.os == "linux"` and not WSL |

`.work` is a boolean asked once at `chezmoi init` (`promptBoolOnce`) and stored in the local `~/.config/chezmoi/chezmoi.toml`. It is never committed.

## Work values

The repo is public. No work hostnames, work email, internal tool names or tokens are committed.

- All work values live in one 1Password item with generic field names (`f_git_email`, `f_url1`, `f_tok1`, ...).
- Templates read it with `onepasswordRead`, only inside `{{ if .work }}`.
- On WSL, chezmoi is configured with `onepassword.command = "op.exe"`.
- Git identity is a template. Personal renders as `CyberFlamingo` with the GitHub noreply email and the personal signing key. Work renders as the work identity with the work signing key.
- Tokens and endpoints render to `private_dot_config/shell/work.env` (mode 0600), sourced by `profile` if present.
- Tokens still end up in plaintext in that file, as they do today. Moving to lazy `op read` calls is a possible later step.

## Personal secrets

Personal (non-work) secrets come from Proton Pass CLI (`pass-cli`) through chezmoi's generic secret functions (`secret.command = "pass-cli"`, `secretJSON "item" "view" ... "--output=json"`). Work secrets keep using the native 1Password functions. Only one generic secret command can be configured, which is fine because 1Password does not use it.

- No personal secret is stored in a file today. This is groundwork only: no template reads from Proton Pass yet.
- Groundwork: `secret.command = "pass-cli"` in the personal profile of `.chezmoi.toml.tmpl`, `pass-cli` installed from a pinned release with a checksum (`.chezmoiexternal.toml`, not `curl | bash`), and a short README note with the template pattern to use when the first secret appears.
- Verify as part of the groundwork: `pass-cli login`, then reading one test item, on the personal Linux desktop and on WSL. Headless login and credential storage on no-GUI machines are not yet confirmed. Requires a paid Proton Pass plan.

## Toolchains

mise replaces asdf and nvm; uv handles Python.

- mise manages Node, Go and other runtimes, and installs prebuilt CLI tools through its `aqua:` backend (shfmt, ripgrep, fd, delta, ...), replacing the cargo and `go install` steps. Config is `~/.config/mise/config.toml`, rendered from a template.
- uv manages Python versions, virtualenvs and tools (`uv tool` replaces `requirements-pipx.txt`).
- Interactive shells use `mise activate`; non-interactive contexts use shims.
- Migration: `mise generate config --tool-versions` from the existing asdf versions; remove asdf, its plugin `set-env` hooks, and `ASDF_DATA_DIR` (currently under `$XDG_CONFIG_HOME`).

## Shell layer

zsh is the default shell. bash and fish stay for machines too slow for zsh.

- One shared layer provides env (XDG, PATH), aliases, and tool init (mise, starship, fzf). Aliases and env come from a single data file rendered into POSIX and fish formats, so the shells cannot drift.
- Only interactive UX is per-shell: plugins, keybindings, completion, history settings.
- Prompt is starship in all three shells. Slow machines can fall back to a plain prompt.
- zsh4humans is removed. Plain `.zshrc` with plugins (autosuggestions, syntax highlighting, completions, fzf integration) as pinned `.chezmoiexternal.toml` entries. No plugin manager, no runtime downloads, no auto-update.
- Parity checklist (verified per shell): PATH and XDG variables, aliases, prompt, mise activation, fzf bindings, history size and options, word-movement and delete keybindings, ssh/git completion.
- Known problems in the current zsh setup to remove: `.zshenv` z4h bootstrap fetching an unpinned branch, auto-update every 28 days, unused ssh-teleport placeholders, a second `compinit` in `.zshrc.local`, the Debian bashrc paste, `HISTSIZE=1000`, and startup-time evals (`dircolors`, `rbenv`, pipx argcomplete, asdf completions).

## System files

Files outside `$HOME` (privoxy, dnscrypt, dnsmasq, NetworkManager, `ssh_config.d`, the router config) live in a `system/` tree that chezmoi ignores. A `run_onchange_` script installs them on Linux with `sudo install`. The router is deployed over SSH by a script run from the desktop (`scp`/`ssh` using a named host alias), so nothing needs to be installed on the router.

## Shared files

- `profile`, `aliases`, shell rc files become templates. WSL-only settings (`DISPLAY`, the `op.exe` alias, `ssh.exe` as `core.sshCommand`, the 1Password signing program path) sit in `{{ if .wsl }}` blocks.
- `.chezmoiignore` skips the desktop-only files (conky, glava, autostart, mozc, gsettings) on WSL and Windows, and Windows-only files elsewhere.
- Submodules (kakoune `plug.kak`) and the kakoune source clone become pinned entries in `.chezmoiexternal.toml`.
- Package installs (apt; mise and uv handle toolchains and CLI tools) become `run_onchange_` scripts. Package lists are refreshed for Ubuntu 24.04.

## Windows

- chezmoi's destination is `%USERPROFILE%`. Files under `AppData/Local/...` in the source land in `%LOCALAPPDATA%`. Scripts and templates read the variable via `$env:LOCALAPPDATA` or `{{ env "LOCALAPPDATA" }}`.
- `C/ProgramData/bin` is removed. `C:\ProgramData` is outside the destination and is machine-wide, not per-user.
- `decentsec` is deleted. A managed laptop gets its baseline from IT.
- `upall` is rewritten as a non-elevated `winget upgrade --all` (no pause, no UAC prompt). Chocolatey is no longer used. Windows Update is left to the OS and the organisation's update policy, not scripted. It is launched at logon by a `.cmd` in `AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/`.
- The Windows chezmoi instance is separate from the WSL one: same repo, separate clone and `chezmoi.toml`.

## Migration order

Each step is its own commit.

1. Shell audit and cleanup on the current layout (z4h stays for now): measure zsh startup, delete the Debian/grml paste and the duplicate `compinit`, fix or drop the slow evals, write the parity checklist and bring bash and fish up to it.
2. Delete the dead configs listed under Scope.
3. chezmoi skeleton: convert to the source layout with `chezmoi add`, add `.chezmoi.toml.tmpl` and `.chezmoiignore`. Split `profile` and `config/git/config` into templates: work values to the 1Password item, keep the useful changes (Bun, WSL lines), discard the rest of the uncommitted diff (including the `.p10k.zsh` churn).
4. Replace zsh4humans with plain zsh, pinned plugin externals and starship. Replace asdf, nvm and pipx with mise and uv.
5. Add the `system/` tree and its install script (Linux), the router deploy script, the Linux dnsmasq config and dnscrypt blocklist replacement, and the Windows `upall` rewrite.
6. Remove dotbot, `meta/`, `install`, `bootstrap/`. Write a real README.
7. Quick install: split package lists into a minimal tier and a full tier (see Deferred).

Other cleanup folded into steps 3 to 5: restore the XDG npm config, convert `alacritty.yml` to TOML, refresh package lists for Ubuntu 24.04.

## Deferred

Quick install vs full install, done last: package lists live in `.chezmoidata/` with a minimal tier (shortest list needed to be productive) and a full tier. An install-tier value chosen at `chezmoi init` selects which tier the `run_onchange_` scripts apply.

## Testing

- `chezmoi diff` and `chezmoi apply --dry-run --verbose` with `--destination` pointed at a scratch directory.
- A full `chezmoi init --apply` in a fresh WSL distro with `.work=false`, which exercises the no-1Password path.
- gitleaks as a pre-commit hook, plus review of `git diff --cached` before each commit.
- The cutover to the real home happens last, after `chezmoi diff` shows only intended changes.

## Guardrails

- Never commit `profile` or `config/git/config` from the current working tree as they are.
- This repo uses a repo-local git identity (personal name, noreply email, personal signing key). Verify `git config user.email` before committing.
- Template item and field names must not reveal internal tool or system names.

## Open items

- Headless login and credential storage for `pass-cli` on WSL and no-GUI machines.
