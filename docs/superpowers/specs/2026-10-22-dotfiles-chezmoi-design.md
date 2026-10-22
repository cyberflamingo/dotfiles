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

Dropped: macOS, Kali, server, OpenWrt, and the privoxy, dnsmasq and dnscrypt configs (`bootstrap/macOS`, `meta/configs/{mac,kali,server,openwrt}`, `etc/`).

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

## Shared files

- `profile`, `aliases`, shell rc files become templates. WSL-only settings (`DISPLAY`, the `op.exe` alias, `ssh.exe` as `core.sshCommand`, the 1Password signing program path) sit in `{{ if .wsl }}` blocks.
- `.chezmoiignore` skips the desktop-only files (conky, glava, autostart, mozc, gsettings) on WSL and Windows, and Windows-only files elsewhere.
- Submodules (kakoune `plug.kak`) and the kakoune source clone become pinned entries in `.chezmoiexternal.toml`.
- Package installs (apt, asdf plugins) become `run_onchange_` scripts. Package lists are refreshed for Ubuntu 24.04.

## Windows

- chezmoi's destination is `%USERPROFILE%`. Files under `AppData/Local/...` in the source land in `%LOCALAPPDATA%`. Scripts and templates read the variable via `$env:LOCALAPPDATA` or `{{ env "LOCALAPPDATA" }}`.
- `C/ProgramData/bin` is removed. `C:\ProgramData` is outside the destination and is machine-wide, not per-user.
- `decentsec` is deleted. A managed laptop gets its baseline from IT.
- `upall` is rewritten as a non-elevated `winget upgrade --all` (no pause, no UAC prompt). Chocolatey is no longer used. Windows Update is left to the OS and the organisation's update policy, not scripted. It is launched at logon by a `.cmd` in `AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/`.
- The Windows chezmoi instance is separate from the WSL one: same repo, separate clone and `chezmoi.toml`.

## Migration order

Each step is its own commit.

1. Delete the dead configs listed under Scope.
2. Split `profile` and `config/git/config`: move work values to the 1Password item, keep the useful changes (asdf, Bun, WSL lines), discard the rest of the uncommitted diff (including the `.p10k.zsh` churn).
3. Convert to the chezmoi source layout with `chezmoi add`, templating the shared files.
4. Add `.chezmoiexternal.toml`, the `run_onchange_` package scripts, and the Windows `upall` rewrite.
5. Remove dotbot, `meta/`, `install`, `bootstrap/`. Write a real README.

Cleanup items folded into steps 2 to 4: pick the primary shell and decide whether bash and fish stay, drop nvm in favor of asdf, replace the Debian/grml paste in `.zshrc.local`, restore the XDG npm config, convert `alacritty.yml` to TOML.

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

- Decide the primary shell (zsh assumed) and whether bash and fish remain.
