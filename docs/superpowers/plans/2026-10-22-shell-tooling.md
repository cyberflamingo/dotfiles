# Shell Tooling Implementation Plan (mise, starship, zoxide, plain zsh)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (this plan has user-gated steps) to implement it task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace asdf, nvm and pipx-for-tools with mise and uv, z4h with plain zsh and pinned plugins, p10k with starship, and z.lua with zoxide, in bash, zsh and fish, so that no shell start spawns a Windows process and `z` works everywhere.

**Architecture:** mise installs the tools (node, go, uv, starship, zoxide, fzf) from pinned versions in one chezmoi-managed config. Every interactive shell runs `mise activate`, then the same small set of integrations (fzf, zoxide, starship). zsh is rebuilt without a framework: the option set z4h applied, `compinit` with a daily-rebuilt cache, four plugins pinned as chezmoi archive externals, and the user's own key bindings ported to plain widgets. The parity test gains a `COMMANDS` check, and the clean-room container now runs zsh too, because nothing downloads itself on first start any more.

**Tech Stack:** mise v2026.10.17, starship, zoxide, fzf (0.51 or newer), uv, zsh 5.9, fish, bash; zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, fzf-tab.

**Spec:** `docs/superpowers/specs/2026-10-22-dotfiles-chezmoi-design.md`, migration step 4. The `system/` tree, the Windows `upall` rewrite and dotbot removal are plan 2c.

---

## Decisions already made by the user

| Topic | Decision |
|---|---|
| Prompt | starship in all three shells |
| oh-my-zsh bits kept | `sudo` (Esc Esc), copypath and clipboard helpers; also fzf, `z`, and the `..` and `...` commands. Dropped: web-search, npm, pip, systemadmin |
| Tab completion | fzf-tab, pinned |
| `~w` (Windows home) | derived from `$PATH`, no Windows process |
| Versions | node 22.17.0, go 1.27.1 (what asdf has today); uv, starship, zoxide, fzf pinned to the latest at install time |

## Ground rules

- Branch `shell-tooling`, created with `git switch -c shell-tooling origin/main`. The home directory is now managed by chezmoi in file mode: editing this checkout changes nothing in `~` until `chezmoi apply`. The source directory is `/home/alex/src/dotfiles`.
- Make the smallest edit that does the job. Keep the user's comments and files: this plan lists exact replacements, and the new `.zshrc` keeps the user's own lines verbatim (they are marked in Task 4).
- Test in a scratch directory (`/tmp/run-scratch.sh`-style helper, Task 1 Step 1) and in the clean-room container before touching `~`. Applying to `~` is Task 6 and is user-gated.
- Never print secrets; no internal names in tracked files (`tests/denylist-check.sh` runs on commit); no `powershell.exe` or registry probing.
- The Bash tool runs zsh: use explicit lists, and run multi-line scripts as files with `bash script.sh`.
- Commits: short subject, then `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. Check `git config user.email` first. If signing fails with a 1Password error, ask the user to unlock 1Password; never skip signing.
- z4h and its cache (`~/.cache/zsh4humans`) stay on disk until Task 7, so rolling back is `git revert` plus `chezmoi apply`.

## File structure

| Path (under the repo root) | Action | Responsibility |
|---|---|---|
| `home/dot_config/mise/config.toml` | Create | Pinned tool versions. |
| `home/dot_config/starship.toml` | Create | Prompt configuration. |
| `home/dot_profile` | Modify | Drop asdf, add the mise shims to `PATH`, drop `_ZL_DATA`. |
| `home/dot_aliases` | Modify | Add `..`. |
| `home/dot_bashrc` | Modify | Drop asdf and the old completions, add mise, fzf, zoxide, starship. |
| `home/dot_config/fish/config.fish`, `fish_plugins` | Modify | Same for fish; drop nvm.fish and the fish `z` plugin. |
| `home/dot_config/zsh/dot_zshenv` | Rewrite | Empty apart from a comment (the z4h bootstrap goes). |
| `home/dot_config/zsh/dot_zshrc` | Rewrite | Plain zsh, keeps the user's own lines. |
| `home/dot_config/zsh/dot_zshrc.local` | Modify | Drop the asdf block. |
| `home/dot_config/zsh/dot_p10k*.zsh` | Delete | p10k is replaced by starship. |
| `home/.chezmoiexternal.toml` | Modify | Four pinned zsh plugins. |
| `home/dot_local/bin/executable_{clipcopy,clippaste,copypath}` | Create | Shell-agnostic clipboard helpers. |
| `tests/shell-parity.sh`, `tests/clean-room.sh` | Modify | `COMMANDS` check; zsh and mise in the clean room. |

---

### Task 1: Install mise and the tools

**Files:**
- Create: `home/dot_config/mise/config.toml`

- [ ] **Step 1: Install mise from a pinned, checksum-verified release**

```bash
cd /tmp && rm -rf mise-dl && mkdir mise-dl && cd mise-dl
curl -fsSL -o mise.tar.gz https://github.com/jdx/mise/releases/download/v2026.10.17/mise-v2026.10.17-linux-x64.tar.gz
echo "17565e268c5542d8ce944321e17af81e0b741b65af4aa7e8e010ee77376a4aa3  mise.tar.gz" | sha256sum --check
tar -xzf mise.tar.gz mise/bin/mise
install -m 0755 mise/bin/mise ~/.local/bin/mise
cd /tmp && rm -rf mise-dl
mise --version
```

Expected: `mise.tar.gz: OK`, then `2026.10.17 linux-x64 ...`.

- [ ] **Step 2: Resolve the exact tool versions**

```bash
for t in uv starship zoxide fzf; do printf '%-9s %s\n' "$t" "$(mise latest "$t")"; done
mise ls-remote node | grep -x '22.17.0' ; mise ls-remote go | grep -x '1.27.1'
```

Expected: one version per tool (record them), and `22.17.0` and `1.27.1` listed. fzf must be 0.51 or newer; if `mise latest fzf` prints an older one, stop and ask the user.

- [ ] **Step 3: Write the config with exact versions**

Write `home/dot_config/mise/config.toml`, replacing each `X.Y.Z` with the version printed in Step 2:

```toml
# Tools managed by mise. Exact versions on purpose: change them here, then
# `chezmoi apply` and `mise install`. `mise upgrade --bump` shows newer ones.
[tools]
node = "22.17.0"
go = "1.27.1"
uv = "X.Y.Z"
starship = "X.Y.Z"
zoxide = "X.Y.Z"
fzf = "X.Y.Z"
```

Check that no placeholder is left: `grep -c 'X.Y.Z' home/dot_config/mise/config.toml` must print `0`. (Executed on 2026-10-22 with uv 0.13.4, starship 1.27.0, zoxide 0.10.0, fzf 0.74.5.)

- [ ] **Step 4: Apply into a scratch home and install the tools there**

Write `/tmp/run-scratch.sh` (the same helper as in plan 2a, now pointing at this checkout):

```bash
#!/usr/bin/env bash
# usage: [EXCLUDE=...] run-scratch.sh DEST [extra chezmoi flags]
set -euo pipefail
dest=${1:?destination}
shift
printf 'sourceDir = "/home/alex/src/dotfiles"\n[data]\n    work = false\n    wsl = false\n' >/tmp/scratch-chezmoi.toml
rm -rf "$dest" /tmp/scratch-state.boltdb
mkdir -p "$dest"
chezmoi --config /tmp/scratch-chezmoi.toml --persistent-state /tmp/scratch-state.boltdb \
    --destination "$dest" --source /home/alex/src/dotfiles "$@" apply --exclude="${EXCLUDE:-scripts}"
```

```bash
shellcheck /tmp/run-scratch.sh && shfmt -i 4 -bn -ci -d /tmp/run-scratch.sh && echo "lint ok"
bash /tmp/run-scratch.sh /tmp/scratch-home
HOME=/tmp/scratch-home XDG_DATA_HOME=/tmp/scratch-home/.local/share XDG_CONFIG_HOME=/tmp/scratch-home/.config \
    mise install 2>&1 | tail -12
HOME=/tmp/scratch-home XDG_DATA_HOME=/tmp/scratch-home/.local/share XDG_CONFIG_HOME=/tmp/scratch-home/.config \
    mise ls 2>&1 | head
```

Expected: six tools installed under the scratch home and listed with the pinned versions. (The real home is untouched; installing into the real home is Task 6.) mise downloads from the aqua registry with checksum verification where upstream publishes it; if a tool reports a verification failure, stop and report it.

- [ ] **Step 5: Commit**

```bash
git add home/dot_config/mise/config.toml
git commit -F - <<'EOF'
Add mise config with pinned tools

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 2: Shared layer (profile, aliases, starship config)

**Files:**
- Modify: `home/dot_profile`, `home/dot_aliases`
- Create: `home/dot_config/starship.toml`

- [ ] **Step 1: Replace the asdf block in `profile` with the mise shims**

Edit `home/dot_profile`, replace:

```sh
# asdf
export ASDF_DATA_DIR="$XDG_CONFIG_HOME/asdf"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
```

with (shims make the tools available to scripts and editors; interactive shells also run `mise activate`):

```sh
# mise (shims for non-interactive use; interactive shells run `mise activate`)
export PATH="$XDG_DATA_HOME/mise/shims:$PATH"
```

Edit `home/dot_profile`, delete the z.lua block (zoxide replaces it; the one-time import is Task 6):

```sh
# z.lua
export _ZL_DATA=$XDG_DATA_HOME/zlua
```

- [ ] **Step 2: `..` for all shells**

Edit `home/dot_aliases`, replace:

```sh
# Grml-Zsh aliases
alias ...='cd ../../'
```

with:

```sh
# Grml-Zsh aliases
alias ..='cd ..'
alias ...='cd ../../'
```

- [ ] **Step 3: A starship config**

Write `home/dot_config/starship.toml`:

```toml
# https://starship.rs/config/  (a starting point, not a copy of the old p10k look)
add_newline = true
# git on a repo under /mnt/c can be slow
command_timeout = 800

[directory]
truncation_length = 3
truncate_to_repo = true

[cmd_duration]
min_time = 2000
```

- [ ] **Step 4: Commit**

```bash
git add home/dot_profile home/dot_aliases home/dot_config/starship.toml
git commit -F - <<'EOF'
profile: mise shims instead of asdf, add .. alias, starship config

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 3: bash and fish

**Files:**
- Modify: `home/dot_bashrc`, `home/dot_config/fish/config.fish`, `home/dot_config/fish/fish_plugins`

- [ ] **Step 1: bash**

Edit `home/dot_bashrc`, replace the asdf block:

```bash
# asdf
if command -v asdf 1>/dev/null 2>&1; then
    . <(asdf completion bash)

    # Go
    . ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.bash
fi
```

with (all four tools live in `~/.local/share/mise`; `mise` itself is in `~/.local/bin`):

```bash
# mise, then the tools it installs
if [ -x "$HOME/.local/bin/mise" ]; then
    eval "$("$HOME/.local/bin/mise" activate bash)"
    command -v fzf 1>/dev/null 2>&1 && eval "$(fzf --bash)"
    command -v zoxide 1>/dev/null 2>&1 && eval "$(zoxide init bash)"
    command -v starship 1>/dev/null 2>&1 && eval "$(starship init bash)"
fi
```

(`command -v` here is only for tools that exist after `mise activate`; it is fast when they are found early on `PATH`.)

- [ ] **Step 2: fish**

Read `home/dot_config/fish/config.fish` first. Edit it, replace the whole asdf block (from the `# asdf` comment through its closing `end`, the one that sets `ASDF_DATA_DIR`, builds `_asdf_shims` and sources the golang `set-env.fish`) with:

```fish
    # mise, then the tools it installs
    if test -x "$HOME/.local/bin/mise"
        "$HOME/.local/bin/mise" activate fish | source
        command -q fzf; and fzf --fish | source
        command -q zoxide; and zoxide init fish | source
    end
```

In the same file, the existing guarded `starship init fish | source` block stays as it is (it now finds the mise-installed starship). Delete the login-block lines that set `_ZL_DATA` (the `# z.lua` comment and `set -x _ZL_DATA ...`). Delete the `# nvm` comment and `# Handled by jorgebucaran/nvm.fish plugin` line.

Edit `home/dot_config/fish/fish_plugins`, delete the lines `jorgebucaran/nvm.fish` and `jethrokuan/z`. Leave the other plugins as they are.

- [ ] **Step 3: Update the parity test**

Edit `tests/shell-parity.sh`.

Replace `_ZL_DATA` in `VARS` (remove it from the `VSCODE_PORTABLE WEGORC WINEPREFIX _ZL_DATA SSB_HOME BUN_INSTALL` line). Add after the `ALIASES=(...)` definition:

```bash
# Commands every shell must find (functions count: zoxide defines z as one)
COMMANDS=(z mise starship fzf)
```

Add `"$HOME/.local/share/mise/shims"` to `PATH_DIRS`. Extend the three snippets with one more loop each:

- bash: `for c in $PARITY_COMMANDS; do type -t "$c" >/dev/null 2>&1 && printf "PARITY:cmd:%s\n" "$c"; done`
- zsh: `for c in ${=PARITY_COMMANDS}; do (( ${+functions[$c]} + ${+commands[$c]} + ${+aliases[$c]} )) && print -r -- "PARITY:cmd:$c"; done`
- fish:

```
for c in (string split " " -- $PARITY_COMMANDS)
    type -q $c; and printf "PARITY:cmd:%s\n" $c
end
```

In `dump()`, add `PARITY_COMMANDS="$PARITY_COMMANDS"` to the `env -i` command string next to the other `PARITY_*` variables, and `PARITY_COMMANDS="${COMMANDS[*]}"` to the environment of the `script` call.

```bash
shellcheck tests/shell-parity.sh && shfmt -i 4 -bn -ci -d tests/shell-parity.sh && echo "lint ok"
fish -n home/dot_config/fish/config.fish && bash -n home/dot_bashrc && echo "parse ok"
```

- [ ] **Step 4: Commit**

```bash
git add home/dot_bashrc home/dot_config/fish tests/shell-parity.sh
git commit -F - <<'EOF'
bash and fish: mise, fzf, zoxide, starship instead of asdf and nvm

Parity test also checks that z, mise, starship and fzf are found.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 4: zsh without z4h

**Files:**
- Rewrite: `home/dot_config/zsh/dot_zshenv`, `home/dot_config/zsh/dot_zshrc`
- Modify: `home/dot_config/zsh/dot_zshrc.local`, `home/.chezmoiexternal.toml`
- Create: `home/dot_local/bin/executable_{clipcopy,clippaste,copypath}`
- Delete: `home/dot_config/zsh/dot_p10k.zsh`, `dot_p10k-8color.zsh`, `dot_p10k-ascii-8color.zsh`

- [ ] **Step 1: Pin the four plugins**

Tags and their commits at planning time: zsh-autosuggestions v0.7.1 `e52ee8ca55bcc56a17c828767a3f98f22a68d4eb`, zsh-syntax-highlighting 0.8.0 `db085e4661f6aafd24e5acb5b2e17e4dd5dddf3e`, zsh-completions 0.36.0 `28c5bdcaf81bb89e56d0df8267d822c3b8aed9e0`, fzf-tab v1.3.0 `d7e0234614dbe5369fdd760907d12c0e05a4dccc`. Check they are still the latest tags and compute the archive checksums:

```bash
for p in zsh-users/zsh-autosuggestions:e52ee8ca55bcc56a17c828767a3f98f22a68d4eb \
         zsh-users/zsh-syntax-highlighting:db085e4661f6aafd24e5acb5b2e17e4dd5dddf3e \
         zsh-users/zsh-completions:28c5bdcaf81bb89e56d0df8267d822c3b8aed9e0 \
         Aloxaf/fzf-tab:d7e0234614dbe5369fdd760907d12c0e05a4dccc; do
    repo=${p%%:*}; sha=${p##*:}
    printf '%-36s latest tag: %s\n' "$repo" "$(curl -sS "https://api.github.com/repos/$repo/tags?per_page=1" | jq -r '.[0].name + " " + .[0].commit.sha')"
    printf '%-36s sha256: %s\n' "" "$(curl -fsSL "https://github.com/$repo/archive/$sha.tar.gz" | sha256sum | cut -d' ' -f1)"
done
```

If a newer tag exists, ask the user whether to take it; otherwise keep these. Append to `home/.chezmoiexternal.toml`, one entry per plugin, with the printed hash in place of `<hash>` (a literal `<hash>` must never be committed; check with `grep -c '<hash>' home/.chezmoiexternal.toml`, which must print `0`):

```toml
[".local/share/zsh/plugins/zsh-autosuggestions"]
    type = "archive"
    url = "https://github.com/zsh-users/zsh-autosuggestions/archive/e52ee8ca55bcc56a17c828767a3f98f22a68d4eb.tar.gz"
    stripComponents = 1
    checksum.sha256 = "<hash>"

[".local/share/zsh/plugins/zsh-syntax-highlighting"]
    type = "archive"
    url = "https://github.com/zsh-users/zsh-syntax-highlighting/archive/db085e4661f6aafd24e5acb5b2e17e4dd5dddf3e.tar.gz"
    stripComponents = 1
    checksum.sha256 = "<hash>"

[".local/share/zsh/plugins/zsh-completions"]
    type = "archive"
    url = "https://github.com/zsh-users/zsh-completions/archive/28c5bdcaf81bb89e56d0df8267d822c3b8aed9e0.tar.gz"
    stripComponents = 1
    checksum.sha256 = "<hash>"

[".local/share/zsh/plugins/fzf-tab"]
    type = "archive"
    url = "https://github.com/Aloxaf/fzf-tab/archive/d7e0234614dbe5369fdd760907d12c0e05a4dccc.tar.gz"
    stripComponents = 1
    checksum.sha256 = "<hash>"
```

- [ ] **Step 2: The clipboard helpers (scripts, so every shell gets them)**

Write `home/dot_local/bin/executable_clipcopy`:

```sh
#!/bin/sh
# Copy stdin to the system clipboard: Wayland, X11, or Windows from WSL.
if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
    exec wl-copy
elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
    exec xclip -selection clipboard -in
elif [ -n "${DISPLAY:-}" ] && command -v xsel >/dev/null 2>&1; then
    exec xsel --clipboard --input
elif command -v clip.exe >/dev/null 2>&1; then
    exec clip.exe
fi
echo "clipcopy: no clipboard tool found" >&2
exit 1
```

Write `home/dot_local/bin/executable_clippaste`:

```sh
#!/bin/sh
# Print the system clipboard on stdout.
if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-paste >/dev/null 2>&1; then
    exec wl-paste
elif [ -n "${DISPLAY:-}" ] && command -v xclip >/dev/null 2>&1; then
    exec xclip -selection clipboard -out
elif [ -n "${DISPLAY:-}" ] && command -v xsel >/dev/null 2>&1; then
    exec xsel --clipboard --output
fi
echo "clippaste: no clipboard tool found" >&2
exit 1
```

Write `home/dot_local/bin/executable_copypath`:

```sh
#!/bin/sh
# Copy the absolute path of a file or directory (default: the current directory) to the clipboard.
target=${1:-.}
if [ -d "$target" ]; then
    path=$(cd -- "$target" && pwd -P)
else
    dir=$(cd -- "$(dirname -- "$target")" && pwd -P) || exit 1
    path=$dir/$(basename -- "$target")
fi
printf '%s' "$path" | clipcopy && printf 'copied: %s\n' "$path" >&2
```

```bash
chmod +x home/dot_local/bin/executable_{clipcopy,clippaste,copypath}
shellcheck -s sh home/dot_local/bin/executable_{clipcopy,clippaste,copypath} && echo "scripts lint ok"
```

`clipcopy` can use `clip.exe` on WSL when no X clipboard tool exists (a Windows process, but only when the user copies explicitly). `clippaste` has no Windows fallback on purpose: reading the Windows clipboard would need `powershell.exe`, which the user does not want started. `xsel` is installed on this machine, so both work through WSLg.

- [ ] **Step 3: `.zshenv`**

Replace the contents of `home/dot_config/zsh/dot_zshenv` with:

```zsh
# Read by every zsh. Environment lives in ~/.profile (sourced by .zshrc).
```

- [ ] **Step 4: `.zshrc`**

Replace the contents of `home/dot_config/zsh/dot_zshrc` with the file below. Lines marked `# (yours)` are the user's own lines, copied verbatim from the old file; everything else is new. Read the old file once more before writing, and check that every line of it that is not z4h machinery appears here.

```zsh
# Interactive zsh, no framework. Plugins are pinned archives that chezmoi extracts to
# ~/.local/share/zsh/plugins, the prompt is starship (~/.config/starship.toml).
# Environment lives in ~/.profile and aliases in ~/.aliases, shared with bash and fish.

## Options: the set zsh4humans applied, minus its internal ones
setopt always_to_end auto_cd auto_param_slash auto_pushd c_bases auto_menu \
    extended_glob extended_history hist_expire_dups_first hist_find_no_dups \
    hist_ignore_dups hist_ignore_space hist_verify interactive_comments multios \
    no_bg_nice no_flow_control no_prompt_bang prompt_cr prompt_percent prompt_sp \
    share_history typeset_silent hist_save_no_dups no_auto_remove_slash \
    no_list_types no_beep

# zsh does not read ~/.profile by itself
[[ -r ~/.profile ]] && source ~/.profile

# Extend PATH.
path=(~/bin $path)

# Export environment variables.
export GPG_TTY=$TTY

# Tools managed by mise (node, go, uv, starship, zoxide, fzf)
[[ -x $HOME/.local/bin/mise ]] && eval "$("$HOME"/.local/bin/mise activate zsh)"

## Completion: plugin completions and the Alacritty ones on fpath, then compinit
zsh_plugins=${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins
fpath=("$zsh_plugins"/zsh-completions/src "$ZDOTDIR"/.zsh_functions $fpath)
autoload -Uz compinit
[[ -d $XDG_CACHE_HOME/zsh ]] || mkdir -p -- "$XDG_CACHE_HOME"/zsh
_zcompdump=$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION
# Rebuild the dump once a day, otherwise skip the security scan
if [[ -n $_zcompdump(#qN.mh+24) ]]; then
    compinit -d "$_zcompdump"
else
    compinit -C -d "$_zcompdump"
fi
unset _zcompdump

# Improve ssh completions
zstyle ':completion:*:ssh:argument-1:'       tag-order  hosts users
zstyle ':completion:*:scp:argument-rest:'    tag-order  hosts files users
zstyle ':completion:*:(ssh|scp|rdp):*:hosts' hosts

# Source additional local files if they exist.
source "$ZDOTDIR"/.zshrc.local

# Autoload functions.
autoload -Uz zmv

# Define functions and completions.
function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

source "$ZDOTDIR"/.zshrc.grml # Grml-Zsh functions

# Define named directories: ~w <=> Windows home directory on WSL.
# Found on PATH (entries under /mnt/c/Users/<name>/AppData), so no Windows process is started.
if [[ -n $WSL_DISTRO_NAME ]]; then
    for _p in $path; do
        if [[ $_p == /mnt/c/Users/*/AppData/* ]]; then
            hash -d w=${_p%%/AppData/*}
            break
        fi
    done
    unset _p
fi

# Define aliases.
# alias tree='tree -a .git'

# Add flags to existing aliases.
alias ls="${aliases[ls]:-ls} -A"

source "$ZDOTDIR"/.aliases.grml # Grml-Zsh aliases

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt no_auto_menu  # require an extra TAB press to open the completion menu

setopt append_history    # append history list to the history file (default)
setopt longlistjobs      # display PID when suspending processes as well
setopt completeinword    # not just at the end
setopt pushd_ignore_dups # don't push the same dir twice
setopt noglobdots        # * shouldn't match dotfiles. ever.
setopt noshwordsplit     # use zsh style word splitting
setopt noclobber         # prevent from overwriting an existing file

## Key bindings. Widgets are defined before the plugins load, so that they can wrap them.
bindkey -e
bindkey '^[[H' beginning-of-line;  bindkey '^[[1~' beginning-of-line   # Home
bindkey '^[[F' end-of-line;        bindkey '^[[4~' end-of-line         # End
bindkey '^[[3~' delete-char                                            # Delete

# Up/Down search the history for the text before the cursor
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search;   bindkey '^[OA' up-line-or-beginning-search;   bindkey '^P' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search; bindkey '^[OB' down-line-or-beginning-search; bindkey '^N' down-line-or-beginning-search

# Ctrl+Backspace kills a short word, Ctrl+Alt+Backspace a whole shell word
backward-kill-subword() { local WORDCHARS=; zle backward-kill-word }
zle -N backward-kill-subword
bindkey '^H' backward-kill-subword
bindkey '^[^?' backward-kill-word;  bindkey '^[^H' backward-kill-word

bindkey '^_' undo;  bindkey '^[[Z' undo  # undo the last command line change
bindkey '^[/' redo                       # redo the last undone command line change

#k# jump to after first word (for adding options)
bindkey '^F' jump_after_first_word
#k# A smart shortcut for \kbd{fg<enter>}
bindkey '^Z' grml-zsh-fg

# Esc Esc: put sudo in front of the command line (or of the last command)
sudo-command-line() {
    [[ -z $BUFFER ]] && LBUFFER="$(fc -ln -1)"
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N sudo-command-line
bindkey '\e\e' sudo-command-line

# Alt+Left/Right/Up/Down: cd into the previous, next, parent or a child directory
typeset -ga _dir_back _dir_fwd
typeset -g _dir_skip=
_dir_track() {
    if [[ -n $_dir_skip ]]; then _dir_skip=; return; fi
    _dir_back+=("$OLDPWD")
    _dir_fwd=()
}
chpwd_functions+=(_dir_track)
cd-back() {
    (( $#_dir_back )) || return
    local d=$_dir_back[-1]
    _dir_back[-1]=()
    _dir_fwd+=("$PWD")
    _dir_skip=1
    builtin cd -- "$d" && zle reset-prompt
}
cd-forward() {
    (( $#_dir_fwd )) || return
    local d=$_dir_fwd[-1]
    _dir_fwd[-1]=()
    _dir_back+=("$PWD")
    _dir_skip=1
    builtin cd -- "$d" && zle reset-prompt
}
cd-up() { builtin cd .. && zle reset-prompt }
cd-down() {
    local d
    zle -I
    d=$(print -rl -- *(-/N) | fzf --height=40% --reverse) || { zle reset-prompt; return }
    [[ -n $d ]] && builtin cd -- "$d"
    zle reset-prompt
}
for _w in cd-back cd-forward cd-up cd-down; zle -N $_w
unset _w
bindkey '^[[1;3D' cd-back;  bindkey '^[[1;3C' cd-forward
bindkey '^[[1;3A' cd-up;    bindkey '^[[1;3B' cd-down

## Terminal title
_set_title() { print -Pn '\e]0;%n@%m: %~\a' }
precmd_functions+=(_set_title)

## fzf (Ctrl-R, Ctrl-T, Alt-C), then fzf-tab on Tab, then the rest
(( $+commands[fzf] )) && source <(fzf --zsh)
source "$zsh_plugins"/fzf-tab/fzf-tab.plugin.zsh
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
source "$zsh_plugins"/zsh-autosuggestions/zsh-autosuggestions.zsh
(( $+commands[starship] )) && eval "$(starship init zsh)"

## zsh-syntax-highlighting has to be sourced last
source "$zsh_plugins"/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```


The `# (yours)` markers in the first draft of this plan are gone from the file: the user's own lines are simply kept as they were. What was dropped on purpose: `setopt ignore_eof` and the `z4h-eof` binding (together they made Ctrl+D close the shell cleanly under the p10k prompt; without the binding `ignore_eof` would make Ctrl+D do nothing, and plain zsh already exits on Ctrl+D), every `zstyle ':z4h:...'` line, `z4h install/init/source/load/bindkey`, the oh-my-zsh libs and the `npm`, `pip`, `systemadmin` and `web-search` plugins (the user dropped them), `z.lua`, the `POSTEDIT` hack and the "Prompt (p10k)" comment (both belonged to the p10k two-line prompt), and z4h's SSH teleport and direnv settings (both were off).

- [ ] **Step 5: `.zshrc.local`**

Edit `home/dot_config/zsh/dot_zshrc.local`, delete the whole asdf block:

```zsh
# asdf
if command -v asdf 1>/dev/null 2>&1; then
    # append completions to fpath
    fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)
    # initialise completions with ZSH's compinit
    autoload -Uz compinit && compinit

    # Go
    . ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh
fi
```

Also delete the block that sources `/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh` if it exists (the pinned plugin is loaded by `.zshrc`; on a machine with the apt package the plugin would load twice), and change the comment above the `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE` export to `# change suggestion color (the plugin itself is loaded by .zshrc from ~/.local/share/zsh/plugins)`, keeping the export. Keep everything else: the user's history settings, zstyles, the `dircolors` and `lesspipe` lines, key bindings for Ctrl+arrows, the pipx completion and the Bun completion.

- [ ] **Step 6: Remove p10k**

```bash
git rm -q home/dot_config/zsh/dot_p10k.zsh home/dot_config/zsh/dot_p10k-8color.zsh home/dot_config/zsh/dot_p10k-ascii-8color.zsh
```

- [ ] **Step 7: Syntax checks**

```bash
zsh -n home/dot_config/zsh/dot_zshrc && zsh -n home/dot_config/zsh/dot_zshrc.local && zsh -n home/dot_config/zsh/dot_zshenv && echo "zsh files parse"
```

- [ ] **Step 8: Commit**

```bash
git add home
git commit -F - <<'EOF'
zsh without z4h: plain zsh, pinned plugins, starship

The option set and the user's key bindings are ported to plain zsh.
fzf-tab, autosuggestions, syntax highlighting and completions are
pinned archives. p10k and z4h's startup call to cmd.exe are gone.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 5: Clean-room test with mise and zsh

**Files:**
- Modify: `tests/clean-room.sh`

- [ ] **Step 1: A zsh smoke test that asserts things**

Write `tests/zsh-smoke.zsh`: it is sourced inside an interactive zsh, checks `bindkey` for 14 keys against the expected widget (Tab `fzf-tab-complete`, Up/Down `up-line-or-beginning-search` and `down-line-or-beginning-search`, Esc Esc `sudo-command-line`, Alt+arrows `cd-back`, `cd-forward`, `cd-up`, `cd-down`, `^_` `undo`, `^[/` `redo`, Ctrl+F `jump_after_first_word`, Ctrl+Z `grml-zsh-fg`, Ctrl+H `backward-kill-subword`, Ctrl+R `fzf-history-widget`), checks that `z`, `mise`, `starship` and `fzf` resolve, that the syntax-highlighting and autosuggestion functions are loaded, that `$PROMPT` mentions starship and that `auto_cd`, `share_history` and `no_beep` are set, and prints `SMOKE-OK` (exit 0) or `SMOKE-FAIL` (exit 1) with one `FAIL ...` line per problem. Run it as:

```bash
script -qec 'env -i HOME="$HOME" USER="$USER" TERM=xterm-256color LANG=C.UTF-8 PATH=/usr/bin:/bin zsh -ilc "source tests/zsh-smoke.zsh"' /dev/null </dev/null | tr -d '\r' | tail -5
```

It passed on the real config and printed `FAIL bindkey ^I: want fzf-tab-complete, got expand-or-complete` and `SMOKE-FAIL` when Tab was rebound by hand. Edit `.pre-commit-config.yaml`: add `exclude: \.zsh$` to the `shellcheck` and `shfmt` hooks (neither understands zsh).

- [ ] **Step 2: Rewrite the clean room**

`tests/clean-room.sh` now installs `zsh` (apt, 5.9) next to `fish`, installs mise from the same pinned release and checksum as Task 1 into the test user's `~/.local/bin` (create `/home/tester/.local` and `/home/tester/.local/bin` both owned by the user, otherwise chezmoi cannot chmod `.local`), runs `chezmoi init --promptDefaults --apply`, then `mise install starship zoxide fzf`, then `tests/shell-parity.sh` for all three shells and the smoke test above. The in-container steps live in a generated `run.sh` run with `su - tester`, to avoid nested quoting. Run it:

```bash
shellcheck tests/clean-room.sh && shfmt -i 4 -bn -ci -d tests/clean-room.sh && echo "lint ok"
timeout 900 tests/clean-room.sh 2>&1 | tail -25
```

Expected: `chezmoi.tar.gz: OK`, `mise.tar.gz: OK`, a count of applied files (774 on 2026-10-22), `installed 3 tools`, `PASS zsh`, `PASS fish`, `SMOKE-OK`. The first full run on 2026-10-22 found two things worth knowing: the `.local` ownership problem above, and a real bug in `profile` (it used `which` for the editor, and zsh's builtin `which` prints "vi not found" on stdout, which ended up in `EDITOR` on a machine without vi). Fix: use `command -v` in `home/dot_profile` for both `kak` and `vi`.

- [ ] **Step 3: Commit**

```bash
git add tests/clean-room.sh tests/zsh-smoke.zsh .pre-commit-config.yaml home/dot_profile
git commit -F - <<'EOF'
Clean room: install mise and zsh, test all three shells

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

- [ ] **Step 4: Push and open the PR (the user does this)**

```bash
git push -u origin shell-tooling
```

---

### Task 6: Apply on this machine (user-gated)

Ask for an explicit go before each step. Do this after the PR is merged or from the branch; the z4h cache stays on disk, so a rollback is `git revert` plus `chezmoi apply`.

- [ ] **Step 1: The user installs zsh from apt and switches the login shell (needs sudo)**

```
! sudo apt install -y zsh
! chsh -s /usr/bin/zsh
```

This replaces the root-owned musl zsh in `/usr/local/bin` that z4h's installer put there. The change takes effect at the next login. Until then, `/usr/local/bin/zsh` (5.8) still runs the new config; it supports everything used here.

- [ ] **Step 2: Snapshot**

```bash
mkdir -p ~/.cache/shell-tooling-cutover && chmod 700 ~/.cache/shell-tooling-cutover
cd ~/.cache/shell-tooling-cutover
cp -a ~/.config/zsh zsh-before; cp -a ~/.profile profile-before; cp -a ~/.bashrc bashrc-before
bash -lc 'env | cut -d= -f1 | sort' > env-names-before.txt
( cd /tmp; for k in user.name user.email user.signingkey gpg.format gpg.ssh.program core.sshCommand; do printf '%s %s\n' "$k" "$(git config --get "$k" | sha256sum | cut -c1-12)"; done ) > git-effective-before.txt
```

- [ ] **Step 3: Apply and install the tools**

```bash
chezmoi diff --exclude=templates | head -40      # expect: the files changed in this plan
chezmoi apply
mise install
mise ls
```

- [ ] **Step 4: Import the z.lua history into zoxide**

```bash
zoxide import --from z "${XDG_DATA_HOME:-$HOME/.local/share}/zlua"
zoxide query -ls | head -5
```

Expected: the entries (98 lines in the data file at planning time) are imported; `query` lists the highest-ranked directories.

- [ ] **Step 5: Verify**

```bash
tests/shell-parity.sh
bash -lc 'env | cut -d= -f1 | sort' > /tmp/env-names-after.txt
diff ~/.cache/shell-tooling-cutover/env-names-before.txt /tmp/env-names-after.txt
( cd /tmp; for k in user.name user.email user.signingkey gpg.format gpg.ssh.program core.sshCommand; do printf '%s %s\n' "$k" "$(git config --get "$k" | sha256sum | cut -c1-12)"; done ) | diff - ~/.cache/shell-tooling-cutover/git-effective-before.txt && echo "same git identity"
hyperfine -i --warmup 3 --runs 20 -N 'bash -ilc exit' 'zsh -ilc exit' 'fish -ilc exit'
```

Also run the smoke test on the real home: `script -qec 'zsh -ilc "source tests/zsh-smoke.zsh"' /dev/null </dev/null | tr -d '\r' | tail -5` (expect `SMOKE-OK`). Expected: `PASS zsh`, `PASS fish`; the only differences in env names are `_ZL_DATA` and `ASDF_DATA_DIR` gone and `MISE_*` added; `same git identity`; zsh startup lower than before (record the numbers). Then the user opens a new terminal and checks by hand, since key bindings and the Tab menu cannot be tested without a person: Tab opens the fzf menu; Up/Down search by prefix; Esc Esc toggles `sudo`; Alt+Left/Right/Up/Down change directory; Ctrl+R opens fzf history; `z <name>` and `zi` work; `..` and `...` work; `~w` completes on WSL; the prompt is starship. If Tab shows zsh's own menu instead of fzf, add `zstyle ':completion:*' menu no` at the end of `.zshrc.local`.

- [ ] **Step 6: Confirm no Windows process is started**

```bash
hyperfine -i --warmup 1 --runs 5 -N 'zsh -ilc exit' >/dev/null
grep -c 'cmd.exe' ~/.config/zsh/.zshrc ~/.config/zsh/.zshenv ~/.config/zsh/.zshrc.local
```

Expected: `0` for each file. (z4h's own `cmd.exe /c set` is in the z4h cache, which nothing loads any more.)

---

### Task 7: Cleanup after a week of use (user-gated)

- [ ] Remove the z4h cache and the old zsh: `rm -rf ~/.cache/zsh4humans`, `sudo rm /usr/local/bin/zsh`, and the `/usr/local/bin/zsh` line from `/etc/shells`.
- [ ] Remove asdf: `rm -rf ~/.config/asdf ~/.local/bin/asdf ~/.tool-versions` (mise reads `.tool-versions`, so remove it only after `mise ls` shows node from `config.toml`).
- [ ] Delete `~/.cache/shell-tooling-cutover` and `~/.local/share/zlua` once zoxide has the history.
- [ ] Plan 2c deletes `bootstrap/Linux/install-zsh.sh` and the nvm install step along with dotbot.

---

## Changes after measuring (2026-10-22)

Applying Task 6 showed startup got slower: with `mise activate` bash went from 37 to 121 ms, fish from 35 to 88 ms and zsh from 150 to 166 ms. Cause, measured: `mise activate` 22 ms plus the `mise hook-env` it runs at once (25 ms) in every shell; a mise shim costs 27 ms per call and a prompt through one 44 ms instead of 14 ms, so shims are not an option for the prompt tools.

Decision (user): no `mise activate`. `~/.profile` (and the fish login block) put the real bin directories of the installed tools on `PATH`, read from a cache file `~/.cache/mise-bin-paths` that is rebuilt when `~/.config/mise/config.toml` or `~/.local/share/mise/installs` is newer (remove the file to force it). The shims stay behind them for non-interactive use. Per-directory tool versions are the price: a project's own version needs `mise exec`. Result: bash 54 ms, zsh 107 ms, fish 32 ms.

Related changes in the same commit: `.bashrc` is sourced at the end of `~/.profile` (it needs the PATH, and the earlier `HISTFILE` fallback becomes harmless); `LESS='-iRFXMx4'` (z4h set it) in profile and fish, and `LESS` in the parity test; `starship init <shell> --print-full-init` is called directly because the plain form spawns it a second time.

Also learned while applying: the first verification used `bash -lc 'env'`, which inherits the caller's environment, so it hid differences (removed NVM and token variables looked like losses). Compare environment names with `env -i`, as the parity test does.

## Regression found after the cutover (2026-10-23)

asdf's Node held global npm packages (`@googleworkspace/cli` 0.22.5, `@devcontainers/cli` 0.86.0, `opencode-ai` 1.14.19, `snyk` 1.1297.3) and asdf's shims also covered a Go tool (`gofumpt`). Once asdf left `PATH`, `gws`, `devcontainer`, `opencode`, `snyk` and `gofumpt` were missing in every new shell; the shell the work ran in still had the asdf shims on its inherited `PATH`, which hid it. The npm `prefix=${XDG_DATA_HOME}/npm` line had put globals in a directory that was never on `PATH`, so it only worked through asdf's reshim.

Fix: `gws` and `devcontainer` are declared in `home/dot_config/mise/config.toml.tmpl` inside `{{ if .work }}` (they are only used on the work machine; `npm:` backend, same versions); the user no longer uses `snyk` and `opencode`, and nothing references `gofumpt` (no config, no shell history, no VS Code settings on the WSL side), so those three were installed once and then removed again. The `prefix` line is gone from the npmrc, and the dead rbenv lines are removed (no Ruby, rbenv or gem is installed; mise can manage Ruby if that changes).

Two things about the `npm:` backend: it does not run package install scripts, so `@googleworkspace/cli` needs its post-install step run by hand after every install of a new version (`mise exec -- node install.js` in `~/.local/share/mise/installs/npm-googleworkspace-cli/<version>/node_modules/.mise/@googleworkspace+cli@<version>/node_modules/@googleworkspace/cli`; it downloads the release archive and verifies its published sha256). Check what a machine should have with `PARITY_EXTRA_COMMANDS='gws devcontainer' tests/shell-parity.sh`.

Also: the old `plug.kak` clone was at a 2022 commit while the pin is current upstream. kakoune loads the same with both (one existing error from the `kakoune-snippets` plugin appears with either version).

## Self-review against the spec

| Spec item | Task |
|---|---|
| mise + uv replace asdf, nvm, pipx-for-tools | 1, 2, 3, 4 |
| zoxide `z` in all shells, history import | 1, 3, 4, 6 |
| z4h replaced by plain zsh, pinned plugins, no runtime downloads | 4 |
| starship prompt in all three shells | 2, 3, 4 |
| Parity checklist: `z`, mise activation, fzf bindings | 3, 5 |
| No `cmd.exe /c set` at shell start | 4, 6 |
| Clean-room test covers zsh | 5 |

Not here: `system/` tree, the router deploy script, dnsmasq and dnscrypt fixes, the Windows `upall` rewrite, dotbot removal (plan 2c); a pipx-to-`uv tool` migration (the pipx completion blocks stay until then); CI for the clean-room test (blocked by the account billing lock).

## Known risks

- Key bindings, the fzf-tab feel and the starship look cannot be tested without a person; Task 6 Step 5 lists what to try. The cd-forward and cd-down widgets approximate z4h's (a back/forward stack and an fzf picker); `Ctrl+Backspace` and `Ctrl+Alt+Backspace` approximate z4h's word kills.
- mise downloads tool binaries from GitHub releases through the aqua registry. Versions are pinned in `config.toml`; verification depends on what each upstream publishes.
- zsh 5.8 (the current musl build) runs the new config; 5.9 arrives with the apt package in Step 1.
- The `nvm` and `asdf` leftovers stay on disk until Task 7, so `node` could come from either if the shims are removed from `PATH`: check `command -v node` points into `~/.local/share/mise` after Step 3.
