# chezmoi Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (this plan has user-gated steps) to implement it task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the dotbot-linked files into a chezmoi source tree, add the work/personal templates, and prove with a clean-room container that a fresh machine ends up with the same files. The cutover on the live machine is the last, user-gated task.

**Architecture:** `.chezmoiroot` points at `home/`, so `docs/`, `tests/`, `etc/`, `meta/` and the other non-home files stay out of the chezmoi source state. Files keep their content: the move is renames only (`git mv`), checked byte-for-byte against the old layout. Only three things become templates: the chezmoi config, and two one-line files that render the work values from 1Password. Everything else is plain. All the work happens in a **separate git worktree**, so the live checkout (whose files the user's `~` symlinks point at) stays on the old layout until the cutover.

**Tech Stack:** chezmoi 2.73.3 (file mode), 1Password CLI through `op.exe` on WSL, Docker for the clean-room test, bash.

**Spec:** `docs/superpowers/specs/2026-10-22-dotfiles-chezmoi-design.md`, migration step 3, plus the part of step 4 that replaces the `plug.kak` submodule. z4h removal, mise/uv/zoxide, the `system/` tree and the Windows side are plans 2b and 2c. dotbot, `meta/`, `install` and `bootstrap/` stay until plan 2c.

---

## Ground rules

- Two checkouts: `/home/alex/src/dotfiles` (the live one, kept on `main`, never touched until Task 6) and `/home/alex/src/dotfiles-chezmoi` (a worktree on branch `chezmoi-skeleton`, where every task except the cutover runs). `~/.profile`, `~/.config/zsh`, `~/.config/git` and the other dotbot symlinks point into the live checkout; a `git switch`, `checkout`, `stash` or `reset` there changes the user's real shell and git config.
- In every command below, `WT=/home/alex/src/dotfiles-chezmoi` and `LIVE=/home/alex/src/dotfiles`. Each script sets them itself.
- This plan renames files; it does not edit their contents, except the `.gitignore` and pre-commit scope lines named below. Keep the user's comments and files as they are.
- Never print secrets. `~/.config/shell/work.env` and `config/git/config.work` stay untracked.
- The Bash tool runs zsh: write explicit lists, not unquoted variables that need word splitting, and run multi-line scripts as files with `bash script.sh`.
- No internal tool names, hostnames or company terms in any tracked file. `tests/denylist-check.sh` runs on commit.
- Commits: short subject, then `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. Verify `git config user.email` prints the personal noreply address in the worktree first. If signing fails with a 1Password error, ask the user to unlock 1Password and retry; never skip signing.
- No `powershell.exe` or registry probing. `op.exe` is run by the user, not by the agent, because its output is secret.

## What the user does first (outside this plan)

The work values move to two 1Password Secure Notes, so no variable name or internal term ever appears in this public repo.

| Item (vault `Private`, or the user's choice) | Notes body |
|---|---|
| `dotfiles-work-env` | The full text of `~/.config/shell/work.env` |
| `dotfiles-work-git` | The full text of `config/git/config.work` (the work git identity) |

The templates read `op://Private/dotfiles-work-env/notesPlain` and `op://Private/dotfiles-work-git/notesPlain`. If the user picks another vault, only those two strings change (Task 3 Step 4). Rotating the tokens is the user's job, in 1Password and on each service.

## File structure

| Path | Action | Responsibility |
|---|---|---|
| `.chezmoiroot` | Create | Contains `home`. |
| `home/` | Create (by `git mv`) | The chezmoi source state. |
| `home/.chezmoi.toml.tmpl` | Create | Per-machine data (`work`, `wsl`) and the `op.exe` setting. |
| `home/.chezmoiignore` | Create | Desktop-only files on WSL. |
| `home/.chezmoiexternal.toml` | Create | Pinned `plug.kak` archive, replacing the submodule. |
| `home/dot_config/private_shell/private_work.env.tmpl` | Create | Renders the work env note when `.work`. (`.config` itself must stay `dot_config`: chezmoi rejects a target directory that is `dot_config` in one place and `private_dot_config` in another.) |
| `home/dot_config/git/private_config.work.tmpl` | Create | Renders the work git note when `.work`. |
| `tests/clean-room.sh` | Create | Applies the dotfiles in a fresh Ubuntu container and runs the parity test. |
| `.gitignore`, `.pre-commit-config.yaml`, `.gitmodules` | Modify | Remove stale entries, follow the moved paths. |
| `README.md` | Modify | Bootstrap instructions. |

---

### Task 1: Worktree and chezmoi binary

**Files:** none (a worktree, and `~/.local/bin/chezmoi`)

- [ ] **Step 1: Put the live checkout back on `main` and create the worktree**

The live checkout is currently on `chezmoi-skeleton`, created from the same commit as `main`, so switching does not change any file.

```bash
cd /home/alex/src/dotfiles
git rev-parse main origin/main      # both lines must be identical
git switch main
git worktree add /home/alex/src/dotfiles-chezmoi chezmoi-skeleton
mv docs/superpowers/plans/2026-10-22-chezmoi-skeleton.md /home/alex/src/dotfiles-chezmoi/docs/superpowers/plans/ 2>/dev/null || true
git status --short
cd /home/alex/src/dotfiles-chezmoi && git branch --show-current && git config user.email
```

Expected: two identical SHAs, `git status` showing only ` M config/kak/plugins/plug.kak` in the live checkout, and `chezmoi-skeleton` plus the personal noreply address in the worktree. If the two SHAs differ, stop: the live checkout is behind `origin/main` and must not be switched.

- [ ] **Step 2: Download, verify and install chezmoi**

```bash
cd /tmp && rm -rf chezmoi-dl && mkdir chezmoi-dl && cd chezmoi-dl
curl -fsSL -o chezmoi.tar.gz https://github.com/twpayne/chezmoi/releases/download/v2.73.3/chezmoi_2.73.3_linux_amd64.tar.gz
echo "6e5827598cbfc02d132b04f95b5ea10efb5b79230e2a4a0e52df4af144a8ee9f  chezmoi.tar.gz" | sha256sum --check
tar -xzf chezmoi.tar.gz chezmoi
install -m 0755 chezmoi ~/.local/bin/chezmoi
cd /tmp && rm -rf chezmoi-dl
chezmoi --version
```

Expected: `chezmoi.tar.gz: OK`, then `chezmoi version v2.73.3, ...`.

- [ ] **Step 3: Check the flags this plan uses**

```bash
chezmoi init --help | grep -E 'promptBool|promptDefaults|source' | head
chezmoi --help | grep -E -- '--config|--destination|--override-data|--source' | head
```

Expected: `--promptBool`, `--promptDefaults`, `-S, --source`, `-c, --config`, `-D, --destination`, `--override-data` all listed. If `--promptBool` is missing, use `--promptDefaults` plus `--override-data` wherever this plan says `--promptBool`.

- [ ] **Step 4: Write the scratch-apply helper**

chezmoi keeps a persistent state file keyed by destination path. Without a fresh one per run, a recreated scratch directory makes chezmoi ask "has changed since chezmoi last wrote it?" and fail for lack of a TTY. Write `/tmp/run-scratch.sh`:

```bash
#!/usr/bin/env bash
# usage: [EXCLUDE=...] run-scratch.sh DEST [extra chezmoi flags]
# Applies the worktree into DEST with a throwaway config and state file.
set -euo pipefail
dest=${1:?destination}
shift
printf 'sourceDir = "/home/alex/src/dotfiles-chezmoi"\n[data]\n    work = false\n    wsl = false\n' >/tmp/scratch-chezmoi.toml
rm -rf "$dest" /tmp/scratch-state.boltdb
mkdir -p "$dest"
chezmoi --config /tmp/scratch-chezmoi.toml --persistent-state /tmp/scratch-state.boltdb \
    --destination "$dest" --source /home/alex/src/dotfiles-chezmoi "$@" apply --exclude="${EXCLUDE:-scripts}"
```

Lint it with shellcheck and shfmt like the other scripts. With `--config` pointing at `/tmp`, nothing is written to the real `~/.config/chezmoi`; the only thing created in `~` is chezmoi's download cache under `~/.cache/chezmoi`.

---

### Task 2: Move the dotbot-linked files into `home/`

Run in the worktree: `cd /home/alex/src/dotfiles-chezmoi`.

**Files:**
- Create: `.chezmoiroot`, `home/` (by renames)
- Modify: `.gitmodules`

- [ ] **Step 1: Check for names chezmoi would misread**

```bash
cd /home/alex/src/dotfiles-chezmoi
echo "templates:"; git ls-files | grep -E '\.tmpl$' || echo none
echo "attribute-like names:"; git ls-files | grep -E '(^|/)(dot_|private_|executable_|symlink_|exact_|run_|once_|before_|after_|create_|modify_|remove_|empty_|readonly_|literal_)' || echo none
echo "symlinks and gitlinks in the index:"; git ls-files -s | awk '$1=="120000" || $1=="160000" {print $1, $4}'
```

Expected: `none`, `none`, and ten gitlinks: `config/kak/plugins/plug.kak` (replaced by an external in this plan) and the nine dotbot submodules under `meta/` (untouched until plan 2c). Any other symlink, gitlink or attribute-like name: stop and ask the user how to name it.

- [ ] **Step 2: Write the move script**

Write `/tmp/move-to-home.sh` (not into the repo):

```bash
#!/usr/bin/env bash
# One-time: move the dotbot-linked files into the chezmoi source layout (home/).
set -euo pipefail
cd /home/alex/src/dotfiles-chezmoi

# old repo path -> path relative to $HOME; fails for files dotbot did not link
target_of() {
    case $1 in
        editorconfig | profile | bashrc | bash_logout | zshenv | aliases) printf '.%s' "$1" ;;
        config/* | gnupg/* | local/bin/*) printf '.%s' "$1" ;;
        *) return 1 ;;
    esac
}

# $1 = path relative to $HOME, $2 = git file mode -> chezmoi source path
source_of() {
    local target=$1 mode=$2 part out='' i last
    local parts=()
    IFS=/ read -ra parts <<<"$target"
    last=$((${#parts[@]} - 1))
    for i in "${!parts[@]}"; do
        part=${parts[i]}
        [[ $part == .* ]] && part="dot_${part#.}"
        [[ $i -eq 0 && $part == dot_gnupg ]] && part="private_$part"
        [[ $i -eq $last && $mode == 100755 ]] && part="executable_$part"
        out+="${out:+/}$part"
    done
    printf '%s' "$out"
}

mkdir -p home
moved=0
while IFS= read -r -d '' rec; do
    mode=${rec%% *}
    path=${rec#*$'\t'}
    [[ $mode == 160000 ]] && continue # submodule, handled by an external
    target=$(target_of "$path") || continue
    dest="home/$(source_of "$target" "$mode")"
    mkdir -p "$(dirname "$dest")"
    git mv -- "$path" "$dest"
    moved=$((moved + 1))
done < <(git ls-files -s -z)
echo "moved $moved files"
```

- [ ] **Step 3: Lint it, then run it**

```bash
shellcheck /tmp/move-to-home.sh && shfmt -i 4 -bn -ci -d /tmp/move-to-home.sh && echo "lint ok"
bash /tmp/move-to-home.sh
cd /home/alex/src/dotfiles-chezmoi
git status --short | awk '{print $1}' | sort | uniq -c
ls home
```

Expected: `lint ok`, `moved 62 files` (the tracked files under `config/`, `gnupg/` and `local/bin/` plus the six root files), a status of `R` entries only, and `home` containing `dot_aliases`, `dot_bash_logout`, `dot_bashrc`, `dot_config`, `dot_editorconfig`, `dot_local`, `dot_profile`, `dot_zshenv`, `private_dot_gnupg`.

- [ ] **Step 4: Remove the submodule that an external replaces, add `.chezmoiroot`**

```bash
cd /home/alex/src/dotfiles-chezmoi
git rm -q --cached config/kak/plugins/plug.kak
rm -rf config/kak/plugins/plug.kak
printf '%s\n' home > .chezmoiroot
git config -f .gitmodules --remove-section 'submodule.config/kak/plugins/plug.kak'
git add .gitmodules .chezmoiroot
grep -c 'plug.kak' .gitmodules || echo "plug.kak removed from .gitmodules"
```

Expected: `plug.kak removed from .gitmodules`. The other eight dotbot submodules stay until plan 2c.

- [ ] **Step 5: Verify nothing was lost: compare every old file with the file chezmoi writes**

Write `/tmp/equiv-check.sh`:

```bash
#!/usr/bin/env bash
# Compare every dotbot-linked file at $BASE with the file chezmoi writes to $SCRATCH.
set -euo pipefail
cd /home/alex/src/dotfiles-chezmoi
base=${1:?base commit}
scratch=${2:?scratch home}

target_of() {
    case $1 in
        editorconfig | profile | bashrc | bash_logout | zshenv | aliases) printf '.%s' "$1" ;;
        config/* | gnupg/* | local/bin/*) printf '.%s' "$1" ;;
        *) return 1 ;;
    esac
}

checked=0 bad=0
while IFS=$'\t' read -r -d '' meta path; do
    mode=${meta%% *}
    [[ $mode == 160000 ]] && continue
    target=$(target_of "$path") || continue
    checked=$((checked + 1))
    if [[ ! -f $scratch/$target ]]; then
        echo "MISSING $target"
        bad=$((bad + 1))
        continue
    fi
    if ! git cat-file blob "$base:$path" | cmp -s - "$scratch/$target"; then
        echo "DIFFERENT $target"
        bad=$((bad + 1))
    fi
    if [[ $mode == 100755 && ! -x $scratch/$target ]]; then
        echo "NOT-EXECUTABLE $target"
        bad=$((bad + 1))
    fi
done < <(git ls-tree -r -z "$base")
echo "checked $checked files, $bad problems"
[[ $bad -eq 0 ]]
```

`git ls-tree -r -z` prints `<mode> <type> <sha>\t<path>\0`; the loop splits on the tab. Run chezmoi into a scratch directory, with externals and scripts skipped (the `plug.kak` entry does not exist yet) and `wsl` false so nothing is ignored:

```bash
shellcheck /tmp/equiv-check.sh && shfmt -i 4 -bn -ci -d /tmp/equiv-check.sh && echo "lint ok"
EXCLUDE=externals,scripts bash /tmp/run-scratch.sh /tmp/scratch-home
bash /tmp/equiv-check.sh origin/main /tmp/scratch-home
```

Expected: `checked N files, 0 problems` with the same N as in Step 3. `MISSING`, `DIFFERENT` or `NOT-EXECUTABLE` lines mean a renaming rule in Step 2 is wrong for that path: fix the script, then in the worktree run `git reset --hard origin/main` (safe: nothing live depends on the worktree; ask the user first anyway) and redo Steps 3 to 5.

- [ ] **Step 6: Do not commit yet**

The tree is consistent only after Task 3 adds the templates and fixes the stale entries. Continue to Task 3.

---

### Task 3: Templates, ignore list, external, stale entries

Run in the worktree.

**Files:**
- Create: `home/.chezmoi.toml.tmpl`, `home/.chezmoiignore`, `home/.chezmoiexternal.toml`, `home/dot_config/private_shell/private_work.env.tmpl`, `home/dot_config/git/private_config.work.tmpl`
- Modify: `.gitignore`, `.pre-commit-config.yaml`

- [ ] **Step 1: The chezmoi config template**

Write `home/.chezmoi.toml.tmpl`:

```
{{- $work := promptBoolOnce . "work" "Is this a work machine" false -}}
{{- $wsl := false -}}
{{- if eq .chezmoi.os "linux" -}}
{{-   $wsl = .chezmoi.kernel.osrelease | lower | contains "microsoft" -}}
{{- end -}}
sourceDir = {{ .chezmoi.workingTree | quote }}

[data]
    work = {{ $work }}
    wsl = {{ $wsl }}
{{ if $wsl }}
# 1Password lives on the Windows side
[onepassword]
    command = "op.exe"
{{ end }}
```

- [ ] **Step 2: Ignore the desktop-only files on WSL**

Write `home/.chezmoiignore`:

```
{{ if .wsl }}
.config/autostart
.config/conky
.config/glava
.config/mozc
{{ end }}
```

- [ ] **Step 3: Replace the submodule with a pinned archive**

Compute the checksum of the archive at the commit the submodule recorded (`cf02b00f3764cbd03ce9ab6eec2f4eed035c0737`):

```bash
curl -fsSL https://github.com/robertmeta/plug.kak/archive/cf02b00f3764cbd03ce9ab6eec2f4eed035c0737.tar.gz | sha256sum
```

Write `home/.chezmoiexternal.toml`, putting the printed hash in the `checksum.sha256` line:

```toml
[".config/kak/plugins/plug.kak"]
    type = "archive"
    url = "https://github.com/robertmeta/plug.kak/archive/cf02b00f3764cbd03ce9ab6eec2f4eed035c0737.tar.gz"
    stripComponents = 1
    checksum.sha256 = "<64 hex digits printed above>"
```

The angle-bracket text above is a stand-in for the hash: it must be replaced by the real value before saving. Check with `grep -c '<64' home/.chezmoiexternal.toml`, which must print `0`.

- [ ] **Step 4: The two work templates (one generic line each)**

Write `home/dot_config/private_shell/private_work.env.tmpl` (the `private_` attribute goes on the `shell` directory and the file, never on `.config`):

```
{{- if .work -}}
{{ onepasswordRead "op://Private/dotfiles-work-env/notesPlain" | trim }}
{{ end -}}
```

Write `home/dot_config/git/private_config.work.tmpl`:

```
{{- if .work -}}
{{ onepasswordRead "op://Private/dotfiles-work-git/notesPlain" | trim }}
{{ end -}}
```

`| trim` drops whatever trailing whitespace the note has, so the rendered file is the note plus exactly one newline, with no leading blank line (the first version of these templates rendered both, which made the output differ from the existing local files). On a machine where `.work` is false the templates render nothing and chezmoi does not create the files; `config/git/config` includes `config.work` and git ignores a missing include.

- [ ] **Step 5: Remove stale entries**

Edit `.gitignore`: delete every group whose paths start with `config/` (the `# Z shell`, `# Fish`, `# Kakoune folders`, `# Mozc`, `# tmux`, `# cmus folders` groups, and the `# Machine-local git overrides` group with `config/git/config.work`), each with its comment. Those runtime files live in `~/.config`, not in the repo. Keep the generic groups (`# Folder view configuration files`, `# Thumbnail cache files`, `# Files that might appear on external disks`).

Edit `.pre-commit-config.yaml`: change both `files: ^(tests|local/bin)/` lines to `files: ^(tests|home/dot_local/bin)/`. The pins stay as they are.

- [ ] **Step 6: Run the equivalence check again, now with the external and the templates**

```bash
cd /home/alex/src/dotfiles-chezmoi
bash /tmp/run-scratch.sh /tmp/scratch-home
bash /tmp/equiv-check.sh origin/main /tmp/scratch-home
ls /tmp/scratch-home/.config/kak/plugins/plug.kak | head -3
test ! -e /tmp/scratch-home/.config/shell/work.env && echo "no work.env when work=false"
```

Expected: `checked N files, 0 problems`, a `plug.kak` directory listing, and `no work.env when work=false`.

- [ ] **Step 7: Check the WSL ignore list**

```bash
EXCLUDE=scripts,externals bash /tmp/run-scratch.sh /tmp/scratch-home2 --override-data '{"wsl": true}'
ls /tmp/scratch-home2/.config | tr '\n' ' '; echo
```

Expected: the list has no `autostart`, `conky`, `glava` or `mozc`.

- [ ] **Step 8: Lint and commit**

```bash
cd /home/alex/src/dotfiles-chezmoi
pre-commit run --all-files
git add home .chezmoiroot .gitmodules .gitignore .pre-commit-config.yaml
git status --short | awk '{print $1}' | sort | uniq -c
```

Check the status output: renames and adds under `home/`, and modifications of `.gitmodules`, `.gitignore` and `.pre-commit-config.yaml`; no `work.env` or `config.work`. Then:

```bash
git commit -F - <<'EOF'
Move dotfiles to a chezmoi source tree

.chezmoiroot points at home/. Files are renamed, not edited, and a byte
comparison against the old layout passes. Add the chezmoi config
template, WSL ignore list, a pinned plug.kak archive in place of the
submodule, and two templates that render the work values from 1Password.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 4: Clean-room test in a fresh Ubuntu container

Run in the worktree.

**Files:**
- Create: `tests/clean-room.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Apply the dotfiles in a clean Ubuntu container and run the parity test there.
# This is the closest thing to a fresh machine. zsh is skipped: z4h downloads
# itself on first start, which a clean-room test should not do.
#
# Usage: tests/clean-room.sh [image]    (default: ubuntu:24.04)

set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
image=${1:-ubuntu:24.04}
chezmoi_version=2.73.3
chezmoi_sha256=6e5827598cbfc02d132b04f95b5ea10efb5b79230e2a4a0e52df4af144a8ee9f

docker run --rm -i -v "$repo":/src:ro "$image" bash -s -- "$chezmoi_version" "$chezmoi_sha256" <<'EOF'
set -euo pipefail
version=$1
sha256=$2

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends ca-certificates curl git fish less >/dev/null

cd /tmp
curl -fsSL -o chezmoi.tar.gz "https://github.com/twpayne/chezmoi/releases/download/v${version}/chezmoi_${version}_linux_amd64.tar.gz"
echo "${sha256}  chezmoi.tar.gz" | sha256sum --check
tar -xzf chezmoi.tar.gz chezmoi
install -m 0755 chezmoi /usr/local/bin/chezmoi

useradd --create-home --shell /bin/bash tester
cp -a /src /home/tester/dotfiles
chown -R tester:tester /home/tester/dotfiles

su - tester -c '
    set -euo pipefail
    cd ~/dotfiles
    chezmoi init --source ~/dotfiles --promptDefaults --apply --exclude=scripts
    echo "--- applied files:"; chezmoi managed | wc -l
    echo "--- parity (bash, fish):"
    ~/dotfiles/tests/shell-parity.sh bash fish
'
EOF
```

- [ ] **Step 2: Lint and run**

```bash
cd /home/alex/src/dotfiles-chezmoi
chmod +x tests/clean-room.sh
shellcheck tests/clean-room.sh && shfmt -i 4 -bn -ci -d tests/clean-room.sh && echo "lint ok"
tests/clean-room.sh 2>&1 | tail -25
```

Expected: `chezmoi.tar.gz: OK`, a count of managed files, and `PASS fish` (with bash as the reference and only fish listed, the result printed is fish's). A `FAIL fish` diff in a clean container shows real drift between `profile` and `config.fish` that the live machine hides (for example a directory that exists there). Fix the side that is wrong, with the smallest edit, and rerun.

If the container cannot reach `github.com` or the Ubuntu mirrors, the script fails at `apt-get` or `curl`; report that to the user and do not work around it.

- [ ] **Step 3: Commit**

```bash
git add tests/clean-room.sh
git commit -F - <<'EOF'
Add clean-room test in an Ubuntu container

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 5: README

Run in the worktree.

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add a short bootstrap section**

Read `README.md` first. Keep every existing line. Insert, after the `# dotfiles` intro paragraph, a section headed `## Install` that says: on a new Linux or WSL machine, install chezmoi from a pinned, checksum-verified release (the exact commands are in `tests/clean-room.sh`), then run `chezmoi init --apply cyberflamingo/dotfiles`; `chezmoi init` asks once whether this is a work machine; work values are read from 1Password (`op`, or `op.exe` on WSL) and a personal machine reads nothing; edit files in the source directory (`chezmoi cd`) and run `chezmoi apply`, and run `chezmoi re-add` after changing a file in `~` directly; checks are `pre-commit run --all-files`, `tests/shell-parity.sh` and `tests/clean-room.sh`.

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -F - <<'EOF'
README: install with chezmoi

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 6: Cutover on this machine (user-gated)

Ask the user for an explicit go before every step. It replaces the live symlinks with files chezmoi writes. The live checkout (`/home/alex/src/dotfiles`, old layout) is not modified, so rolling back is a matter of re-creating the symlinks. Do this **before** merging the PR, with the worktree as the chezmoi source.

**Files:** none (the home directory)

- [ ] **Step 1: Pre-checks the user must confirm**

- The two 1Password Secure Notes exist, and the user has run the notes check from Step 1b in their own terminal: both lines print `match`.
- The tokens that were in `work.env` are stored in the notes (rotation can follow).
- Task 4's clean-room test passes.

The local `~/.config/shell/work.env` and `config.work` do **not** need to be deleted: once the notes render to exactly the same bytes, `chezmoi apply` rewrites them with identical content. The cutover snapshot (Step 2) keeps a copy anyway.

- [ ] **Step 1b: Check that the notes render to the existing files (the user runs this)**

`op.exe` output is secret, so the agent does not run it. Write `/tmp/work-notes-check.sh` for the user:

```bash
#!/usr/bin/env bash
# Compare what the two 1Password notes render to with the current local files.
# Prints short hashes only, never contents. Run it yourself: it calls op.exe.
#
# Usage: bash /tmp/work-notes-check.sh [source-dir]    (default: the chezmoi worktree)
set -euo pipefail

src=${1:-$HOME/src/dotfiles-chezmoi}
cfg=$(mktemp --suffix=.toml)
trap 'rm -f "$cfg"' EXIT
printf '[data]\n    work = true\n    wsl = true\n[onepassword]\n    command = "op.exe"\n' >"$cfg"

check() { # template (relative to home/), local file
    local tmpl=$1 file=$2 a b
    a=$(chezmoi --config "$cfg" --source "$src" execute-template <"$src/home/$tmpl" | sha256sum | cut -c1-12)
    b=$(sha256sum <"$file" | cut -c1-12)
    if [ "$a" = "$b" ]; then
        echo "match   $file ($a)"
    else
        echo "DIFFER  $file (note renders to $a, file is $b)"
    fi
}

check dot_config/private_shell/private_work.env.tmpl "$HOME/.config/shell/work.env"
check dot_config/git/private_config.work.tmpl "$HOME/.config/git/config.work"
```

The user runs `! bash /tmp/work-notes-check.sh`. Both lines must say `match`. A `DIFFER` means the note text is not identical to the local file (most often a copy-paste difference): the user edits the note, or the local file, until they agree. Do not continue until both match.

- [ ] **Step 2: Snapshot the current state**

```bash
mkdir -p ~/.cache/dotfiles-cutover && chmod 700 ~/.cache/dotfiles-cutover
find ~ -maxdepth 3 -lname '*src/dotfiles*' -printf '%p -> %l\n' 2>/dev/null | sort > ~/.cache/dotfiles-cutover/symlinks.txt
wc -l < ~/.cache/dotfiles-cutover/symlinks.txt
bash -lc 'env | cut -d= -f1 | sort' > ~/.cache/dotfiles-cutover/env-names-before.txt
( cd /tmp
  for k in user.name user.email user.signingkey gpg.format gpg.ssh.program core.sshCommand; do
      printf '%s %s\n' "$k" "$(git config --get "$k" | sha256sum | cut -c1-12)"
  done ) > ~/.cache/dotfiles-cutover/git-effective-before.txt
cp -a ~/.config/shell ~/.cache/dotfiles-cutover/shell-backup
git -C /home/alex/src/dotfiles ls-files -z --others -i --exclude-standard -- config gnupg local > ~/.cache/dotfiles-cutover/ignored-runtime-files.z
tr '\0' '\n' < ~/.cache/dotfiles-cutover/ignored-runtime-files.z | wc -l
```

Expected: a count of symlinks (about 40), the snapshot files, and a count of ignored runtime files. Those are files that exist only inside the live repo tree (for example `config/mozc`, `config/cmus/playlists`, `config/newsboat/urls`, fish's `fish_variables` and `functions`, kakoune colors) and would be orphaned when a symlinked directory becomes a real one. The backup directory holds `work.env` with real values: keep it mode 700.

- [ ] **Step 3: Remove the old links, then copy the runtime files into place**

```bash
cut -d' ' -f1 ~/.cache/dotfiles-cutover/symlinks.txt | while read -r l; do rm -- "$l"; done
cd /home/alex/src/dotfiles
while IFS= read -r -d '' f; do
    dest="$HOME/.$f"
    mkdir -p "$(dirname "$dest")"
    cp -a -- "$f" "$dest"
done < ~/.cache/dotfiles-cutover/ignored-runtime-files.z
```

Expected: no errors. `config/mozc/...` becomes `~/.config/mozc/...`, and so on.

- [ ] **Step 4: Initialise, review the diff, apply**

```bash
chezmoi init --source /home/alex/src/dotfiles-chezmoi --promptBool 'Is this a work machine=true'
chezmoi diff --exclude=templates | head -80
```

`--exclude=templates` keeps the two files rendered from 1Password out of the diff, so no secret is printed; Step 1b already proved they equal the existing files. Ask the user to read the diff summary (new files, and differences only where a runtime file from Step 3 was also tracked). Then:

```bash
chezmoi apply
```

If `chezmoi apply` fails on `onepasswordRead` (for example the 1Password prompt did not appear), stop and use the rollback in Step 6.

- [ ] **Step 5: Verify**

```bash
cd /home/alex/src/dotfiles-chezmoi
tests/shell-parity.sh
bash -lc 'env | cut -d= -f1 | sort' > /tmp/env-names-after.txt
diff ~/.cache/dotfiles-cutover/env-names-before.txt /tmp/env-names-after.txt && echo "same variables"
( cd /tmp
  for k in user.name user.email user.signingkey gpg.format gpg.ssh.program core.sshCommand; do
      printf '%s %s\n' "$k" "$(git config --get "$k" | sha256sum | cut -c1-12)"
  done ) | diff - ~/.cache/dotfiles-cutover/git-effective-before.txt && echo "same effective git config"
```

Expected: `PASS zsh`, `PASS fish`, `same variables`, `same effective git config`. A difference in the variable list usually means a token is missing from the 1Password note.

- [ ] **Step 6: Rollback (only if Step 4 or 5 fails)**

```bash
# remove what chezmoi wrote at the link paths, then restore the symlinks from the snapshot
cut -d' ' -f1 ~/.cache/dotfiles-cutover/symlinks.txt | while read -r l; do rm -rf -- "$l"; done
while IFS= read -r line; do
    link=${line%% -> *}
    target=${line#* -> }
    ln -s -- "$target" "$link"
done < ~/.cache/dotfiles-cutover/symlinks.txt
cp -a ~/.cache/dotfiles-cutover/shell-backup/. ~/.config/shell/
```

The links point into the live checkout, which still has the old layout, so the old state is back exactly. The runtime files copied in Step 3 were copies, so nothing is lost.

- [ ] **Step 7: After the PR is merged, repoint chezmoi at the live checkout**

```bash
cd /home/alex/src/dotfiles
git merge --ff-only origin/main        # safe now: no symlink points into this tree any more
chezmoi init --source /home/alex/src/dotfiles --promptBool 'Is this a work machine=true'
chezmoi diff | head -20                # expect no differences
git worktree remove /home/alex/src/dotfiles-chezmoi
```

Expected: an empty or trivial `chezmoi diff`. Edits from now on happen in `/home/alex/src/dotfiles/home/...` followed by `chezmoi apply`.

---

## Self-review against the spec

| Spec item | Task |
|---|---|
| chezmoi source layout from the dotbot-linked files | 2 |
| `.chezmoiroot` keeps docs, tests, `etc/`, `meta/` out of the source state | 2, 3 |
| Per-machine data (`work`, `wsl`) prompted once, stored locally | 3 |
| WSL detection from `.chezmoi.kernel.osrelease` | 3 |
| `onepassword.command = "op.exe"` on WSL | 3 |
| Work values from 1Password, only inside `{{ if .work }}`, no internal names in the repo | 3, plus the Secure Notes layout |
| Desktop-only files ignored on WSL | 3 |
| Submodule replaced by a pinned external | 2, 3 |
| Clean-room test | 4 |
| Bootstrap docs | 5 |
| Cutover with rollback, without losing ignored runtime files | 6 |

Not here, by design: z4h removal, mise/uv/zoxide, starship (plan 2b); the `system/` tree, the router deploy script, the dnsmasq and dnscrypt fixes, the Windows `upall` rewrite, dotbot removal, the kakoune source clone external (plan 2c); a CI job for the clean-room test (blocked by the account billing lock; add it when Actions run again).

## Updating the pinned `plug.kak`

`home/.chezmoiexternal.toml` pins the archive by commit and checksum, so nothing changes until it is edited. To update:

```bash
git ls-remote https://github.com/robertmeta/plug.kak HEAD            # new commit SHA
curl -fsSL https://github.com/robertmeta/plug.kak/archive/<sha>.tar.gz | sha256sum
```

Put the new SHA in the `url` and the printed hash in `checksum.sha256`, then run `chezmoi apply`: chezmoi sees a new URL and downloads it. Check what changed upstream first (`git log` on the compare page); the pin exists so that a compromised or broken upstream cannot reach the shell by itself. Any other pinned external works the same way. A monthly reminder, or a scheduled workflow, can compare the pins with upstream once CI runs again.

## Known risks

- In file mode `chezmoi apply` writes copies. After Task 6 the source of truth is the source directory, not `~`.
- z4h bootstraps itself on first zsh start, so the clean-room test skips zsh; zsh parity comes from Task 6 Step 5 on the live machine.
- The Secure Notes contain the same plaintext tokens `work.env` has today: exposure does not change. Rotation is separate.
- The cutover temporarily uses the worktree as the chezmoi source directory; Step 7 repoints it. If the user never merges, `chezmoi init --source` can be rerun at any time.
