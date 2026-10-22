# Shell Cleanup and Dead Configs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Get the shell configs clean and in parity (bash, zsh, fish) on the current dotbot layout, with work values out of tracked files, and delete the configs for systems no longer in use.

**Architecture:** A test script (`tests/shell-parity.sh`) starts real interactive login shells and diffs their environment variables, PATH entries and aliases against bash. Every shell fix is driven by that diff going green. Shared settings live in `profile` (env) and `aliases` (plain `alias name='value'` lines that bash, zsh and fish can all source); each shell's rc file keeps only interactive behaviour. Work values move to an untracked `~/.config/shell/work.env` and `config/git/config.work`, the same paths chezmoi will render later.

**Tech Stack:** bash, zsh 5.8 (z4h stays until plan 2), fish, hyperfine, git, shellcheck.

**Spec:** `docs/superpowers/specs/2026-10-22-dotfiles-chezmoi-design.md`, migration steps 1 and 2. Later steps (chezmoi skeleton, z4h removal, mise/uv, system files, Windows) get their own plans once this one is done.

---

## Ground rules (apply to every task)

- Work on branch `chezmoi-migration`. Before each commit, `git config user.email` must print `19971275+cyberflamingo@users.noreply.github.com`.
- `~/.profile`, `~/.bashrc`, `~/.aliases`, `~/.config/zsh`, `~/.config/fish` and `~/.config/git` are symlinks into this repo. Every edit is live in the user's shells immediately.
- Keep the user's existing comments and notes. Make the smallest edit that fixes the code: change or delete a line only when it is broken or moves elsewhere, delete a comment only together with the code it describes, and add comments only for new code. Never replace a whole file to reorganise or reword it.
- Stage files by name. Never `git add -A` or `git commit -a`.
- Never print token values. When checking `profile` or `work.env`, print variable names only.
- Do not run `powershell.exe`, registry reads or other Windows-side probes (user rule: they trigger SOC alerts).
- Commit messages: short subject, optional body, then this trailer:
  `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`
- The agent's Bash tool runs zsh, which does not word-split unquoted variables. Write explicit path lists or arrays; a command like `git diff -- $files` silently matches nothing. Check that any scan reports a non-zero count of what it scanned.
- Leave `config/kak/plugins/plug.kak` (dirty submodule pointer) unstaged. Spec step 4 replaces submodules.

## File structure

| Path | Action | Responsibility |
|---|---|---|
| `~/.config/shell/work.env` | Create (untracked, mode 600) | Work tokens, endpoints, WSL `op` alias. Sourced by `profile`. |
| `config/git/config.work` | Create (gitignored) | Work git identity, signing, WSL ssh settings. Included by `config/git/config`. |
| `config/git/config` | Modify | Personal defaults + `[include] path = config.work`. |
| `.gitignore` | Modify | Ignore `config/git/config.work`. |
| `profile` | Modify | Shared env. Gains `PAGER`, `LESS_TERMCAP_*`, `GCC_COLORS`; guards for `~/.local/bin/env` and WSL `DISPLAY`; sources `work.env`. |
| `aliases` | Rewrite | Shared aliases in the one syntax all three shells can read. |
| `bashrc` | Modify | Interactive bash only. |
| `config/zsh/.zshrc`, `config/zsh/.zshrc.local` | Modify | Interactive zsh only. |
| `config/fish/config.fish` | Modify | Env parity with `profile`, interactive fish. |
| `tests/shell-parity.sh` | Create | Parity test. |
| `bootstrap/macOS`, `meta/configs/{mac,kali,server}.conf.yaml`, `etc/caddy`, `etc/ssh/sshd_config`, `etc/*/*.macos` | Delete | Systems no longer in use. |

---

### Task 0: Quarantine work values and commit a clean baseline

**Files:**
- Create: `~/.config/shell/work.env`, `config/git/config.work`
- Modify: `profile`, `config/git/config`, `.gitignore`, `aliases`

- [ ] **Step 1: Check preconditions**

```bash
cd /home/alex/src/dotfiles
git branch --show-current     # chezmoi-migration
git config user.email         # 19971275+cyberflamingo@users.noreply.github.com
git config user.name          # CyberFlamingo
git status --short | wc -l    # 13
```

If any value differs, stop and fix the repo-local identity before continuing (`git config --local user.name ...`).

- [ ] **Step 2: Snapshot what the shells see today (names and hashes only)**

```bash
bash -lc 'env | cut -d= -f1 | sort' > /tmp/env-names-before.txt
wc -l < /tmp/env-names-before.txt

( cd /tmp
  for k in user.name user.email user.signingkey gpg.format gpg.ssh.program core.sshCommand; do
      printf '%s %s\n' "$k" "$(git config --get "$k" | sha256sum | cut -c1-12)"
  done
  for h in https://github.com https://gist.github.com; do
      printf '%s %s\n' "$h" "$(git config --get-all "credential.$h.helper" | sha256sum | cut -c1-12)"
  done ) > /tmp/git-effective-before.txt
cat /tmp/git-effective-before.txt
```

Expected: a line count of env variable names, and eight `name hash` lines.

- [ ] **Step 3: Pick the work-only lines in `profile`**

`profile` changes between sessions (the user already removed and revoked unused tokens), so do not trust fixed line numbers. Print a numbered view with secret values masked:

```bash
awk '{ l=$0; if (l ~ /(TOKEN|KEY|SECRET|PAT|PASSWORD)[A-Z_]*=/) sub(/=.*/, "=<masked>", l); printf "%d: %s\n", NR, l }' profile | sed -n '/asdf/,$p'
```

Work-only means: token, key and secret assignments, internal URLs, hostnames and IDs, work email addresses, and the comment headers that introduce them. Generic lines stay (asdf, the uv env script, Bun, the `BROWSER` comments, `DISPLAY`). Propose line ranges (include the blank line after each block) and get the user's confirmation before continuing. This output is for the terminal only: never copy names, URLs or comments from it into a file tracked in git, including this plan.

- [ ] **Step 4: Move the work blocks into `work.env` and remove them from `profile`**

Put the confirmed ranges in `P` as one sed address list. The value below is an example of the shape only:

```bash
P='147,153p;157,165p'   # EXAMPLE ONLY: use the ranges confirmed in Step 3
D=$(printf '%s' "$P" | sed 's/p/d/g')
( umask 077
  mkdir -p ~/.config/shell
  { printf '%s\n' '# Work-only values. Not tracked in git; chezmoi renders this file from 1Password later.'
    sed -n "$P" profile
    printf '\n%s\n' '# WSL: the 1Password CLI lives on the Windows side'
    printf '%s\n' "alias op='op.exe'"
  } > ~/.config/shell/work.env )
chmod 600 ~/.config/shell/work.env
sed -i "$D" profile
bash -n ~/.config/shell/work.env && echo "work.env parses"
```

Expected: `work.env parses`.

- [ ] **Step 5: Guard two lines in `profile` and source `work.env`**

Edit `profile`, replace:

```sh
. "$HOME/.local/share/../bin/env"
```

with:

```sh
[ -r "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
```

Edit `profile`, replace:

```sh
# Profile necessary for WSL
export DISPLAY=:0
```

with:

```sh
# WSL needs DISPLAY for X apps
if grep -qi microsoft /proc/version 2>/dev/null; then
    export DISPLAY=:0
fi

# Machine-local values (work tokens, endpoints, WSL helpers). Not tracked in git.
if [ -r "$XDG_CONFIG_HOME/shell/work.env" ]; then
    # shellcheck source=/dev/null
    . "$XDG_CONFIG_HOME/shell/work.env"
fi
```

- [ ] **Step 6: Remove the WSL `op` alias from `aliases`**

Edit `aliases`, delete these last two lines (and the blank line above them):

```sh
# 1Password
alias op='op.exe'
```

- [ ] **Step 7: Verify no secrets remain and the environment is unchanged**

```bash
grep -nE 'ghp_|_TOKEN=|_KEY=|SECRET|GH_PAT|PASSWORD' profile aliases || echo "clean"
bash -lc 'env | cut -d= -f1 | sort' > /tmp/env-names-after.txt
diff /tmp/env-names-before.txt /tmp/env-names-after.txt && echo "same variables"
```

Expected: `clean` and `same variables`. A diff means a variable was lost or added: restore the range from `~/.config/shell/work.env` and redo Step 4.

- [ ] **Step 7b: Hand the remaining secrets to the user for 1Password and rotation**

List the variable names now in `work.env` (names only, never values):

```bash
grep -oE '^[[:space:]]*(export )?[A-Za-z_][A-Za-z0-9_]*=' ~/.config/shell/work.env | sed -E 's/^[[:space:]]*(export )?//; s/=$//'
```

Tell the user the list. They store each value in one 1Password item with generic field names (`f_tok1`, `f_tok2`, ...) and then rotate each token on its service. Keep the mapping from field name to variable in the chat only, not in any repo file. Until plan 2 renders `work.env` from 1Password, the user pastes each rotated value into `~/.config/shell/work.env` by hand. Wait for the user to say they have finished storing the values before moving on; rotation can happen in parallel.

- [ ] **Step 7c: Create the local denylist used by the commit scan**

Ask the user for the internal names to guard against (company name, internal tool and host names, work email domain). Write them, one per line, to `~/.config/shell/denylist.txt`:

```bash
( umask 077; ${EDITOR:-vi} ~/.config/shell/denylist.txt )
```

This file is never tracked. Step 12 uses it, so the terms themselves never appear in the repo.

- [ ] **Step 8: Build `config/git/config.work` from the current values**

```bash
cd /home/alex/src/dotfiles
src=config/git/config; dst=config/git/config.work
rm -f "$dst"
for k in user.name user.email user.signingkey gpg.format gpg.ssh.program core.sshCommand; do
    if git config -f "$src" --get "$k" >/dev/null; then
        git config -f "$dst" "$k" "$(git config -f "$src" --get "$k")"
    fi
done
for h in https://github.com https://gist.github.com; do
    git config -f "$src" --get-all "credential.$h.helper" | while IFS= read -r v; do
        git config -f "$dst" --add "credential.$h.helper" "$v"
    done
done
git config -f "$dst" --list | cut -d= -f1
```

Expected key names (values are not printed):

```
user.name
user.email
user.signingkey
gpg.format
gpg.ssh.program
core.sshcommand
credential.https://github.com.helper
credential.https://github.com.helper
credential.https://gist.github.com.helper
credential.https://gist.github.com.helper
```

- [ ] **Step 9: Restore the committed git config, then add the include and the personal defaults**

```bash
git checkout HEAD -- config/git/config
git config -f config/git/config user.name CyberFlamingo
git config -f config/git/config alias.mergemain '!git fetch origin main && git merge origin/main'
git config -f config/git/config --add include.path config.work
tail -4 config/git/config
```

Expected: the last lines are an `[alias]`/`[include]` section ending with `path = config.work`.

- [ ] **Step 10: Ignore the work file and verify the effective git config is unchanged**

Edit `.gitignore`, replace:

```
# Mozc
config/mozc
```

with:

```
# Machine-local git overrides (work identity)
config/git/config.work

# Mozc
config/mozc
```

```bash
git check-ignore -v config/git/config.work

( cd /tmp
  for k in user.name user.email user.signingkey gpg.format gpg.ssh.program core.sshCommand; do
      printf '%s %s\n' "$k" "$(git config --get "$k" | sha256sum | cut -c1-12)"
  done
  for h in https://github.com https://gist.github.com; do
      printf '%s %s\n' "$h" "$(git config --get-all "credential.$h.helper" | sha256sum | cut -c1-12)"
  done ) > /tmp/git-effective-after.txt
diff /tmp/git-effective-before.txt /tmp/git-effective-after.txt && echo "same effective git config"
```

Expected: a `.gitignore:NN:config/git/config.work` line, then `same effective git config`.

- [ ] **Step 11: Ask the user three questions, then act on the answers**

Ask with AskUserQuestion:

1. `config/npm/npmrc` was emptied and `NPM_CONFIG_USERCONFIG` is commented out in `profile`. Restore the XDG npm config, or keep it empty?
   - Restore: `git checkout -- config/npm/npmrc`, then uncomment `# export NPM_CONFIG_USERCONFIG=...` in `profile`.
   - Keep empty: leave both, and in Task 5 remove the `NPM_CONFIG_USERCONFIG` line from `config/fish/config.fish`.
2. `config/zsh/.p10k.zsh` has a 749-line uncommitted diff. Discard it (`git checkout -- config/zsh/.p10k.zsh`; p10k is replaced by starship in plan 2) or keep it (commit it separately)?
3. `config/git/ignore` is untracked and repeats the line already added to `gitignore_global`. Delete it (`rm config/git/ignore`) or keep it?

- [ ] **Step 12: Scan everything to be committed**

```bash
git diff -- profile aliases bashrc config/git/config .gitignore config/fish/config.fish config/zsh/.zshrc config/zsh/.zshrc.local config/kak/kakrc config/git/gitignore_global | grep '^+' > /tmp/added-lines.txt
echo "added lines scanned: $(wc -l < /tmp/added-lines.txt)"   # must be greater than 0
hits=$(
    grep -niE 'ghp_|glpat-|xox[bp]-|AKIA|BEGIN .*PRIVATE KEY|_TOKEN=|_KEY=|SECRET' /tmp/added-lines.txt
    grep -niFf ~/.config/shell/denylist.txt /tmp/added-lines.txt
)
if [ -z "$hits" ]; then
    echo "no secrets or work identifiers in diff"
else
    printf '%s\n' "$hits" | cut -d: -f1 | sed 's/^/hit at added line /'
fi
rm -f /tmp/added-lines.txt
```

Expected: a positive `added lines scanned` count, then `no secrets or work identifiers in diff`. A count of 0 means the scan checked nothing. A hit prints only the line number in the added-lines list (never the text): find it by rerunning the `git diff ... | grep '^+'` pipeline into `sed -n '<n>p'` in the terminal, remove it from the tracked file and move it to `work.env` or `config.work` before committing. The denylist from Step 7c must exist, otherwise the second grep checks nothing.

- [ ] **Step 13: Commit in two parts**

```bash
git add profile aliases config/git/config .gitignore
git commit -F - <<'EOF'
Move work values out of tracked files

Work tokens and endpoints go to ~/.config/shell/work.env, the work git
identity to config/git/config.work (gitignored, included from config).
Guard the uv env script and the WSL DISPLAY setting.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF

git add bashrc config/fish/config.fish config/git/gitignore_global config/kak/kakrc \
    config/zsh/.zshrc config/zsh/.zshrc.local
git commit -F - <<'EOF'
Commit current shell and editor tweaks

Baseline before the shell cleanup: asdf hooks, kakoune formatters,
claude settings ignore.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

Also stage and commit whatever Step 11 decided to keep (`config/npm/npmrc`, `config/zsh/.p10k.zsh`) in a third commit, named after what it is.

- [ ] **Step 14: Confirm the end state**

```bash
git status --short
git log -3 --format='%h %s (%an)'
```

Expected: only ` M config/kak/plugins/plug.kak` remains (plus any untracked file the user chose to keep); the last commits are authored by `CyberFlamingo`.

---

### Task 1: Install the test prerequisites

**Files:** none (system packages)

- [ ] **Step 1: Ask the user to approve and run the install**

fish and hyperfine are not installed. Ask the user to run (it needs sudo):

```
! sudo apt install -y fish hyperfine
```

- [ ] **Step 2: Verify**

```bash
fish --version
hyperfine --version
```

Expected: `fish, version 3.x` (or newer) and `hyperfine 1.x`.

---

### Task 2: Write the parity test and watch it fail

**Files:**
- Create: `tests/shell-parity.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Check that bash, zsh and fish expose the same environment variables, PATH
# entries and aliases. Starts real interactive login shells (inside a pty, as
# z4h expects one) against $HOME and only reads state.
#
# Usage: tests/shell-parity.sh [shell ...]    (default: bash zsh fish)
# Set PARITY_DEBUG=1 to print each shell's raw output to stderr.

set -u -o pipefail

VARS=(
    XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
    EDITOR VISUAL PAGER LESSHISTFILE LESSOPEN LS_COLORS GCC_COLORS
    LESS_TERMCAP_md LESS_TERMCAP_us
    AWS_SHARED_CREDENTIALS_FILE AWS_CONFIG_FILE DOCKER_CONFIG
    CARGO_HOME GOPATH GOBIN JAVA_HOME _JAVA_OPTIONS MINIKUBE_HOME
    TERMINFO TERMINFO_DIRS NPM_CONFIG_USERCONFIG
    PSQLRC PSQL_HISTORY PGPASSFILE PGSERVICEFILE
    GEM_HOME GEM_SPEC_CACHE RBENV_ROOT
    BUNDLE_USER_CONFIG BUNDLE_USER_CACHE BUNDLE_USER_PLUGIN
    VSCODE_PORTABLE WEGORC WINEPREFIX _ZL_DATA SSB_HOME BUN_INSTALL
)

# fish ships its own ll, la, l and grep, so those would pass without our
# config. Only names fish does not define are listed.
ALIASES=(copy move rmv da dir mpip rmcdir isodate)

PATH_DIRS=(
    "$HOME/.local/bin"
    "$HOME/.local/share/cargo/bin"
    "$HOME/.local/share/go/bin"
    "$HOME/.local/share/gem/bin"
    "$HOME/.local/share/rbenv/bin"
    "$HOME/.bun/bin"
)

# The snippets run inside the shell under test, so they must stay unexpanded.
# shellcheck disable=SC2016
BASH_SNIPPET='
for v in $PARITY_VARS; do printf "PARITY:var:%s=%s\n" "$v" "${!v-}"; done
for a in $PARITY_ALIASES; do alias "$a" >/dev/null 2>&1 && printf "PARITY:alias:%s\n" "$a"; done
for p in $PARITY_PATHS; do case ":$PATH:" in *":$p:"*) printf "PARITY:path:%s\n" "$p" ;; esac; done'

# shellcheck disable=SC2016
ZSH_SNIPPET='
for v in ${=PARITY_VARS}; do print -r -- "PARITY:var:$v=${(P)v}"; done
for a in ${=PARITY_ALIASES}; do (( ${+aliases[$a]} + ${+functions[$a]} )) && print -r -- "PARITY:alias:$a"; done
for p in ${=PARITY_PATHS}; do [[ ":$PATH:" == *":$p:"* ]] && print -r -- "PARITY:path:$p"; done'

# shellcheck disable=SC2016
FISH_SNIPPET='
for v in (string split " " -- $PARITY_VARS)
    printf "PARITY:var:%s=%s\n" $v (string join " " -- $$v)
end
for a in (string split " " -- $PARITY_ALIASES)
    functions -q $a; and printf "PARITY:alias:%s\n" $a
end
for p in (string split " " -- $PARITY_PATHS)
    contains -- $p $PATH; and printf "PARITY:path:%s\n" $p
end'

dump() {
    local shell=$1 snippet raw cmd dir
    local existing=()
    # fish_add_path skips directories that do not exist, bash does not: only
    # compare the ones that exist on this machine.
    for dir in "${PATH_DIRS[@]}"; do
        [ -d "$dir" ] && existing+=("$dir")
    done
    case $shell in
        bash) snippet=$BASH_SNIPPET ;;
        zsh) snippet=$ZSH_SNIPPET ;;
        fish) snippet=$FISH_SNIPPET ;;
        *)
            echo "unknown shell: $shell" >&2
            return 2
            ;;
    esac
    # env -i: only the shell's own startup files may set variables. Without it
    # every shell inherits the caller's environment and the test proves nothing.
    # shellcheck disable=SC2016
    cmd='env -i HOME="$HOME" USER="$USER" LOGNAME="$USER" TERM=xterm-256color LANG=C.UTF-8'
    cmd+=' PATH=/usr/local/bin:/usr/bin:/bin'
    # shellcheck disable=SC2016
    cmd+=' PARITY_VARS="$PARITY_VARS" PARITY_ALIASES="$PARITY_ALIASES" PARITY_PATHS="$PARITY_PATHS"'
    cmd+=" $shell -ilc \"\$PARITY_SNIPPET\""
    raw=$(PARITY_VARS="${VARS[*]}" PARITY_ALIASES="${ALIASES[*]}" PARITY_PATHS="${existing[*]}" \
        PARITY_SNIPPET="$snippet" \
        script -qec "$cmd" /dev/null </dev/null | tr -d '\r')
    [ -n "${PARITY_DEBUG:-}" ] && printf '%s\n' "$raw" >&2
    printf '%s\n' "$raw" | grep -a -o 'PARITY:.*' | sed 's/^PARITY://' | tr -s ' ' | sort
}

main() {
    local shells=("$@") ref out diff_out rc=0 s
    [ ${#shells[@]} -eq 0 ] && shells=(bash zsh fish)
    ref=$(dump bash)
    if [ -z "$ref" ]; then
        echo "bash produced no output (try PARITY_DEBUG=1)" >&2
        return 2
    fi
    for s in "${shells[@]}"; do
        [ "$s" = bash ] && continue
        out=$(dump "$s")
        if [ -z "$out" ]; then
            echo "FAIL $s: no output (try PARITY_DEBUG=1)"
            rc=1
            continue
        fi
        if diff_out=$(diff -u --label bash --label "$s" <(printf '%s\n' "$ref") <(printf '%s\n' "$out")); then
            echo "PASS $s"
        else
            echo "FAIL $s"
            printf '%s\n' "$diff_out"
            rc=1
        fi
    done
    return $rc
}

main "$@"
```

- [ ] **Step 2: Make it executable and lint it**

```bash
chmod +x tests/shell-parity.sh
shellcheck tests/shell-parity.sh && shfmt -i 4 -bn -ci -d tests/shell-parity.sh && echo "lint ok"
```

Expected: `lint ok`. Fix any shellcheck or shfmt finding in the script before continuing.

- [ ] **Step 3: Run it and confirm it fails for the expected reasons**

```bash
tests/shell-parity.sh
```

Expected (observed when this plan was executed): `FAIL zsh` with a single differing line (`var:PAGER=` in bash, `var:PAGER=less` in zsh, because z4h exports it), and `FAIL fish` with every `alias:`, `path:` and `var:` line missing or empty. fish loads nothing because `config/fish/config.fish` has a syntax error (the asdf Go line, around line 196: `source (echo $ASDF_DATA_DIR | if test -z $it; ...)`), and fish skips a file it cannot parse. Task 4 fixes that first.

An earlier version of the script without `env -i` showed `PASS zsh` and a half-empty fish diff, because every shell inherited the caller's environment. If the output ever looks too good, check that `env -i` is still in `dump`.

If a shell prints `no output`, rerun with `PARITY_DEBUG=1 tests/shell-parity.sh zsh` and read the raw output. If the pty wrapper itself misbehaves (for example `script` exits before the shell prints), replace the `script -qec ...` call in `dump` with a direct `"$shell" -ilc "$snippet"` call and keep going; the comparison logic is unchanged.

- [ ] **Step 4: Commit the test**

```bash
git add tests/shell-parity.sh
git commit -F - <<'EOF'
Add shell parity test

Diffs env vars, PATH entries and aliases of bash, zsh and fish.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 3: Record the startup baseline

**Files:** none (measurements go in `/tmp` and later in a commit message)

- [ ] **Step 1: Time the three shells**

```bash
hyperfine -i --warmup 3 --runs 20 -N 'bash -ilc exit' 'zsh -ilc exit' 'fish -ilc exit' \
    --export-markdown /tmp/startup-before.md
cat /tmp/startup-before.md
```

Expected: a markdown table with mean and range per shell. If `zsh` fails without a tty (z4h returns early), time it through a pty instead:

```bash
for i in 1 2 3 4 5 6 7 8 9 10; do /usr/bin/time -f %e script -qec 'zsh -ilc exit' /dev/null >/dev/null; done 2>&1 | sort -n | sed -n '5,6p'
```

Record the median (the 5th and 6th values) as the zsh baseline.

- [ ] **Step 2: Profile where zsh spends time**

```bash
sed -i '1i zmodload zsh/zprof' config/zsh/.zshenv
printf '%s\n' 'zprof' >> config/zsh/.zshrc
script -qec 'zsh -ic exit' /dev/null | tr -d '\r' | head -30
git checkout -- config/zsh/.zshenv config/zsh/.zshrc
git status --short
```

Expected: a `zprof` table (name, calls, time) listing the most expensive functions, then `git status --short` showing only the `plug.kak` line again. Note the top five entries; Task 6 should remove or shrink them.

---

### Task 3b: Remove nvm (found by the Task 3 profile)

The profile showed nvm as the largest startup cost (zsh `nvm_auto` 361 ms, about 70 ms more in bash). `node` already resolves to the asdf shim (22.17.0), because asdf's PATH entry comes later in `profile` than `nvm.sh`; the nvm install (22.14.0) is dead weight. The spec drops nvm anyway.

**Files:**
- Modify: `profile`

- [ ] **Step 1: Confirm node comes from asdf in a clean login shell**

```bash
env -i HOME="$HOME" PATH=/usr/bin:/bin bash -lc 'command -v node; node --version'
```

Expected: `.../asdf/shims/node` and `v22.17.0`. If it prints an nvm path, stop and ask the user which Node they want before removing nvm.

- [ ] **Step 2: Remove the nvm block from `profile`**

Edit `profile`, delete these lines and the blank line after them:

```sh
# nvm
export NVM_DIR="$XDG_DATA_HOME"/nvm
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
```

- [ ] **Step 3: Check that node is unchanged and startup improved**

```bash
env -i HOME="$HOME" PATH=/usr/bin:/bin bash -lc 'command -v node; node --version'
hyperfine -i --warmup 3 --runs 20 -N 'bash -ilc exit' 'zsh -ilc exit' --export-markdown /tmp/startup-after-nvm.md
```

Expected: the same asdf node, and a lower mean for bash and zsh than in `/tmp/startup-before.md`.

- [ ] **Step 4: Commit**

```bash
git add profile
git commit -F - <<'EOF'
Remove nvm

node already comes from asdf; sourcing nvm.sh cost about 400 ms per
shell start. The unused ~/.local/share/nvm directory can be deleted.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

Leave `~/.local/share/nvm` on disk; the user can delete it. The nvm install step in `meta/configs/default.conf.yaml` and the `jorgebucaran/nvm.fish` line in `config/fish/fish_plugins` go in plan 2 with the rest of the bootstrap.

---

### Task 4: One aliases file that all three shells can read

**Files:**
- Rewrite: `aliases`
- Modify: `config/fish/config.fish`

- [ ] **Step 0: Fix the fish syntax error so that `config.fish` loads at all**

```bash
fish -n config/fish/config.fish
```

Expected before the fix: an error at the asdf Go line (`Expected end of the statement, but found a string`, around line 196). Edit `config/fish/config.fish`, replace:

```fish
        source (echo $ASDF_DATA_DIR | if test -z $it; echo $HOME/.asdf; else echo $it; end)/plugins/golang/set-env.fish
```

with:

```fish
        if test -f "$ASDF_DATA_DIR/plugins/golang/set-env.fish"
            source "$ASDF_DATA_DIR/plugins/golang/set-env.fish"
        end
```

Check again:

```bash
fish -n config/fish/config.fish && echo "fish config parses"
```

Expected: `fish config parses`. Add `fish -n config/fish/config.fish` to every later fish edit step as the first check.

- [ ] **Step 1: Make minimal edits to `aliases`**

Keep the user's comments and layout; change only what is broken or needed. Edit `aliases`, replace:

```sh
# Imported from bashrc and zshrc
# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
```

with:

```sh
# Imported from bashrc and zshrc
# Only plain `alias name=value` lines here: bash, zsh and fish all source this file.
# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# color support, moved here from bashrc and the fish config
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
```

Edit `aliases`, replace:

```sh
alias move="vm -i"
# safe remove
move_to_trash() {
    if ! [ -x "$(command -v gioo)" ]; then
        echo "Command 'gio' not found, exiting."
        return 127
    fi

    echo "Moving files or directories to the trash..."
    gio trash "$@"
}
alias rmv="move_to_trash"
```

with:

```sh
alias move="mv -i"
# safe remove
alias rmv="gio trash"
```

This fixes two bugs: `vm` was a typo for `mv`, and `move_to_trash` checked for a command named `gioo`, so it always failed. A function also cannot be parsed by fish, which made fish skip the whole file. The color aliases for `fgrep`, `egrep`, `dir` and `vdir` are not carried over (modern grep warns that `fgrep` and `egrep` are obsolescent).

- [ ] **Step 2: Make fish rely on the shared file for aliases**

Edit `config/fish/config.fish`, replace:

```fish
    # enable color support of ls and also add handy aliases
    if test -x /usr/bin/dircolors
        test -r ~/.dircolors && eval (dircolors -c ~/.dircolors) || eval (dircolors -c)
        alias ls='ls --color=auto'
        alias dir='dir --color=auto'
        alias vdir='vdir --color=auto'

        alias grep='grep --color=auto'
        alias fgrep='fgrep --color=auto'
        alias egrep='egrep --color=auto'
    end

    # some more ls aliases
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'

```

with:

```fish
    # enable color support of ls and also add handy aliases
    # (the aliases themselves now live in ~/.aliases)
    if test -x /usr/bin/dircolors
        test -r ~/.dircolors && eval (dircolors -c ~/.dircolors) || eval (dircolors -c)
    end

```

Edit `config/fish/config.fish`, replace:

```fish
    if test -f ~/.aliases
        . ~/.aliases
    end
```

with:

```fish
    if test -f ~/.aliases
        . ~/.aliases
    end

    # fish has no $OLDPWD, so rmcdir overrides the shared alias
    function rmcdir --description 'Remove the current (empty) directory and go up'
        set -l dir $PWD
        cd ..; and rmdir $dir; or cd $dir
    end
```

- [ ] **Step 3: Check that each shell loads the file**

```bash
bash -n aliases && echo "bash parses"
fish -c 'source ~/.aliases; functions -q move; and echo "fish loads aliases"' 2>&1 | tail -3
zsh -fc 'source ~/.aliases; whence -w move' 2>&1 | tail -3
```

Expected: `bash parses`, `fish loads aliases`, `move: alias`.

- [ ] **Step 4: Run the parity test**

```bash
tests/shell-parity.sh
```

Expected: no `alias:` lines left in any diff. Env and PATH lines may still fail (Task 5).

- [ ] **Step 5: Commit**

```bash
git add aliases config/fish/config.fish
git commit -F - <<'EOF'
Make aliases loadable by bash, zsh and fish

Plain alias lines only. Fix move (mv) and drop the move_to_trash
function, which checked for a command named gioo and never worked.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 5: Bring fish's environment in line with `profile`

**Files:**
- Modify: `profile`, `config/fish/config.fish`

- [ ] **Step 1: Add the shared less colors and `PAGER` to `profile`**

The `LESS_TERMCAP_*` exports exist in `bashrc` and `.zshrc.local` but not in fish. Put one copy in `profile` (printf instead of `$'...'`, which is not POSIX; the user's trailing comments are kept). Edit `profile`, replace:

```sh
# LESS
export LESSHISTFILE=-
```

with:

```sh
# LESS
export LESSHISTFILE=-
# printf instead of $'...', which is not POSIX
LESS_TERMCAP_mb=$(printf '\033[1;31m')  # begin blink
LESS_TERMCAP_md=$(printf '\033[1;36m')  # begin bold
LESS_TERMCAP_me=$(printf '\033[0m')     # reset bold/blink
LESS_TERMCAP_so=$(printf '\033[01;33m') # begin reverse video
LESS_TERMCAP_se=$(printf '\033[0m')     # reset reverse video
LESS_TERMCAP_us=$(printf '\033[1;32m')  # begin underline
LESS_TERMCAP_ue=$(printf '\033[0m')     # reset underline
export LESS_TERMCAP_mb LESS_TERMCAP_md LESS_TERMCAP_me LESS_TERMCAP_so LESS_TERMCAP_se LESS_TERMCAP_us LESS_TERMCAP_ue

# Pager
PAGER=$(command -v less)
export PAGER
```

`GCC_COLORS` already matches in all three shells, so it stays where it is.

- [ ] **Step 2: Align `config/fish/config.fish`**

Each edit keeps the existing comments. Edit `config/fish/config.fish`, replace:

```fish
    if test "$EUID" = 0
        umask 002
    else
        umask 022
    end
```

with (`profile` uses 027 for both):

```fish
    if test "$EUID" = 0
        umask 027
    else
        umask 027
    end
```

Edit `config/fish/config.fish`, replace:

```fish
    set -u less (which less)
    set -x PAGER $less
```

with:

```fish
    set -u less (which less)
    set -x PAGER $less

    # Colors for man pages (through less)
    set -x LESS_TERMCAP_mb (printf '\033[1;31m') # begin blink
    set -x LESS_TERMCAP_md (printf '\033[1;36m') # begin bold
    set -x LESS_TERMCAP_me (printf '\033[0m') # reset bold/blink
    set -x LESS_TERMCAP_so (printf '\033[01;33m') # begin reverse video
    set -x LESS_TERMCAP_se (printf '\033[0m') # reset reverse video
    set -x LESS_TERMCAP_us (printf '\033[1;32m') # begin underline
    set -x LESS_TERMCAP_ue (printf '\033[0m') # reset underline
```

Edit `config/fish/config.fish`, replace:

```fish
    # z.lua
    set -x _ZL_DATA $XDG_DATA_HOME/zlua
```

with:

```fish
    # Wine
    set -x WINEPREFIX "$XDG_DATA_HOME"/wineprefixes/default

    # Bun
    set -x BUN_INSTALL "$HOME/.bun"
    fish_add_path --append "$BUN_INSTALL/bin"

    # z.lua
    set -x _ZL_DATA $XDG_DATA_HOME/zlua
```

Edit `config/fish/config.fish`, replace (a file test avoids the `$PATH` walk that makes `command -v` slow on WSL, where `/mnt/c` entries are on the PATH):

```fish
    if command -v rbenv 1>/dev/null 2>&1
        rbenv init - fish | source
```

with:

```fish
    if test -x "$RBENV_ROOT/bin/rbenv" # not `command -v`: it walks the slow /mnt/c PATH entries on WSL
        "$RBENV_ROOT/bin/rbenv" init - fish | source
```

Edit `config/fish/config.fish`, replace:

```fish
    starship init fish | source
```

with:

```fish
    if command -v starship 1>/dev/null 2>&1
        starship init fish | source
    end
```

- [ ] **Step 3: Run the parity test**

```bash
fish -n config/fish/config.fish && bash -n profile && echo "parse ok"
tests/shell-parity.sh
```

Expected: `parse ok`, `PASS zsh`, `PASS fish`. Remaining diff lines are real drift: fix the side that is wrong and rerun.

- [ ] **Step 4: Commit**

```bash
git add profile config/fish/config.fish
git commit -F - <<'EOF'
Bring fish env in line with profile

Same umask (027), PAGER, LESS_TERMCAP_*, WINEPREFIX and Bun. Check
rbenv by file instead of walking PATH. Guard starship init.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 6: Clean up the zsh config

**Files:**
- Rewrite: `config/zsh/.zshrc.local`
- Modify: `config/zsh/.zshrc`

- [ ] **Step 1: Targeted edits in `.zshrc`**

Edit `config/zsh/.zshrc`, replace:

```zsh
zstyle ':z4h:' auto-update      'yes'
```

with (z4h no longer downloads updates at shell start; run `z4h update` by hand until plan 2 removes z4h):

```zsh
zstyle ':z4h:' auto-update      'no'
```

Edit `config/zsh/.zshrc`, replace:

```zsh
# Install or update core components (fzf, zsh-autosuggestions, etc.) and
```

with:

```zsh
# Alacritty (must be on fpath before `z4h init`, which runs compinit)
fpath+=${ZDOTDIR:-~}/.zsh_functions

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
```

Edit `config/zsh/.zshrc`, delete this line (the later `setopt noglobdots` cancels it):

```zsh
setopt glob_dots     # no special treatment for file names with a leading dot
```

- [ ] **Step 2: Targeted deletions in `.zshrc.local`**

Do not rewrite the file: the user's comments stay. Each edit below removes duplicated or dead code together with the comment that describes only that code.

Edit `config/zsh/.zshrc.local`, replace (bigger history, and drop the second `compinit` that `z4h init` makes redundant):

```zsh
# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
export SAVEHIST=1000
HISTFILE="$XDG_STATE_HOME"/zsh/history

# Use modern completion system
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump-"$ZSH_VERSION"

zstyle ':completion:*' cache-path
```

with:

```zsh
# Keep 50000 lines of history within the shell and save it to $HISTFILE:
HISTSIZE=50000
export SAVEHIST=50000
HISTFILE="$XDG_STATE_HOME"/zsh/history

zstyle ':completion:*' cache-path
```

Edit `config/zsh/.zshrc.local`, replace (the same `list-colors` style is set again, after `dircolors`, further down):

```zsh
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt
```

with:

```zsh
zstyle ':completion:*' list-prompt
```

Edit `config/zsh/.zshrc.local`, delete the whole Debian prompt paste, from the comment `# set variable identifying the chroot you work in (used in the prompt below)` through the closing `fi` of the `if [ -n "$force_color_prompt" ]` block, so that `# enable color support` follows directly after the `## Imported from bashrc` area. It only sets bash prompt variables.

Edit `config/zsh/.zshrc.local`, inside the `dircolors` block delete the `alias ls=...` through `alias ip=...` lines (now in `~/.aliases`) and the seven `export LESS_TERMCAP_*` lines (now in `~/.profile`). The `# Take advantage of $LS_COLORS for completion as well` comment and its `zstyle` stay.

Edit `config/zsh/.zshrc.local`, delete the Alacritty block (moved to `.zshrc` in Step 1):

```zsh
# Alacritty
fpath+=${ZDOTDIR:-~}/.zsh_functions

```

Edit `config/zsh/.zshrc.local`, replace (a file test avoids the `$PATH` walk that makes `command -v` slow on WSL):

```zsh
if command -v rbenv 1>/dev/null 2>&1; then
    eval "$(rbenv init -)"
```

with:

```zsh
if [ -x "$RBENV_ROOT/bin/rbenv" ]; then # not `command -v`: it walks the slow /mnt/c PATH entries on WSL
    eval "$("$RBENV_ROOT"/bin/rbenv init - zsh)"
```

Edit `config/zsh/.zshrc.local`, replace:

```zsh
    eval "$(register-python-argcomplete pipx)"
```

with:

```zsh
    # cached, register-python-argcomplete starts Python on every shell
    _pipx_comp="$XDG_CACHE_HOME"/zsh/pipx-completion
    [ -s "$_pipx_comp" ] || register-python-argcomplete pipx >"$_pipx_comp"
    source "$_pipx_comp"
    unset _pipx_comp
```

Left as they are on purpose: the `zsh-autosuggestions` block (its `if [ -f /usr/share/zsh-autosuggestions/... ]` never runs here, so the user's `fg=#999` suggestion color has never applied under z4h; moving the export out of the `if` would change what the user sees, so ask first), the asdf block with its second `compinit` (goes with asdf in plan 2), and `bindkey -e`.

- [ ] **Step 3: Smoke test**

```bash
zsh -n config/zsh/.zshrc.local && echo "parses"
script -qec 'zsh -ilc "print ok; print -r -- \$HISTSIZE; whence -w ll; whence -w _alacritty"' /dev/null | tr -d '\r' | tail -5
```

Expected: `parses`, `ok`, `50000`, `ll: alias`, and `_alacritty: none`. The alacritty completion was never registered on this machine (alacritty is not installed and the committed version prints the same), so `none` is the baseline, not a failure. `print -l $fpath` should list `.../zsh/.zsh_functions`.

- [ ] **Step 4: Run the parity test**

```bash
tests/shell-parity.sh
```

Expected: `PASS zsh` and `PASS fish`.

- [ ] **Step 5: Commit**

```bash
git add config/zsh/.zshrc config/zsh/.zshrc.local
git commit -F - <<'EOF'
Clean up zsh config

Drop the duplicate compinit, the Debian prompt paste and the color
settings now in profile and aliases. Cache pipx completions, check rbenv
by file, bigger history, z4h auto-update off, alacritty fpath before
z4h init.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 7: Clean up the bash config

**Files:**
- Modify: `bashrc`

- [ ] **Step 1: Fix history**

Edit `bashrc`, replace:

```bash
HISTSIZE=1000
HISTFILESIZE=1000
HISTFILE="$XDG_STATE_HOME"/bash/history
```

with (the user's comment above these lines stays):

```bash
HISTSIZE=50000
HISTFILESIZE=50000
# ~/.profile sources this file before it defines the XDG variables, hence the fallback.
# The directory has to exist, otherwise bash silently saves nothing.
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}"/bash/history
mkdir -p "${HISTFILE%/*}"
```

(Before this, `~/.local/state/bash` did not exist and, in login shells, `$XDG_STATE_HOME` was still empty when this file ran, so bash history was never saved.)

- [ ] **Step 2: Remove the aliases and less colors that now live elsewhere**

Edit `bashrc`, inside the `dircolors` block delete the `alias ls=...` through `alias ip=...` lines (now in `~/.aliases`) and the seven `export LESS_TERMCAP_*` lines (now in `~/.profile`), and the blank line they leave before `fi`. The `# enable color support of ls, less and man, and also add handy aliases` comment and the `eval "$(dircolors ...)"` lines stay. `GCC_COLORS` stays too.

- [ ] **Step 3: Cache pipx completions, check rbenv by file, guard the uv env script**

Edit `bashrc`, replace:

```bash
if command -v rbenv 1>/dev/null 2>&1; then
    eval "$(rbenv init -)"
fi
```

with (`command -v` for an absent command walks all of `$PATH`, including the `/mnt/c` entries, and cost about 70 ms here):

```bash
# not `command -v`: it walks the slow /mnt/c PATH entries on WSL. Same fallback as HISTFILE above.
_rbenv="${RBENV_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/rbenv}"/bin/rbenv
if [ -x "$_rbenv" ]; then
    eval "$("$_rbenv" init - bash)"
fi
unset _rbenv
```

Edit `bashrc`, replace:

```bash
    eval "$(register-python-argcomplete pipx)"
```

with:

```bash
    # cached, register-python-argcomplete starts Python on every shell
    _pipx_comp="${XDG_CACHE_HOME:-$HOME/.cache}"/pipx-completion.bash
    [ -s "$_pipx_comp" ] || register-python-argcomplete pipx >"$_pipx_comp"
    # shellcheck source=/dev/null
    . "$_pipx_comp"
    unset _pipx_comp
```

Edit `bashrc`, replace:

```bash
. "$HOME/.local/share/../bin/env"
```

with:

```bash
[ -r "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
```

- [ ] **Step 4: Lint and run the full parity test**

```bash
bash -n bashrc && echo "bashrc parses"
tests/shell-parity.sh
script -qec 'env -i HOME="$HOME" USER="$USER" TERM=xterm-256color PATH=/usr/bin:/bin bash -ilc "echo HISTFILE=\$HISTFILE; ls -d \${HISTFILE%/*}"' /dev/null </dev/null | tr -d '\r' | tail -2
```

Expected: `bashrc parses`, `PASS zsh`, `PASS fish`, and a history path under `~/.local/state/bash` that exists. Do not fix shellcheck notes that were already in the Debian-derived file.

- [ ] **Step 5: Commit**

```bash
git add bashrc
git commit -F - <<'EOF'
Clean up bash config

Fix HISTFILE (bashrc runs before profile defines XDG_STATE_HOME and the
directory did not exist), bigger history, cached pipx completions, and
remove color blocks now in profile and aliases.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 8: Measure again and record the result

**Files:** none

- [ ] **Step 1: Re-time the shells**

```bash
hyperfine -i --warmup 3 --runs 20 -N 'bash -ilc exit' 'zsh -ilc exit' 'fish -ilc exit' \
    --export-markdown /tmp/startup-after.md
cat /tmp/startup-before.md /tmp/startup-after.md
```

Expected: the zsh mean is lower than the Task 3 baseline (no second `compinit` before the zstyles, no pipx Python start). If it is not lower, run the Task 3 Step 2 profile again and look at what dominates; do not claim an improvement.

- [ ] **Step 2: Run the whole parity test one last time**

```bash
tests/shell-parity.sh
```

Expected: `PASS zsh` and `PASS fish`.

- [ ] **Step 3: Record the numbers**

Add a short commit with the before/after means in the body, so the improvement is in the history:

```bash
git commit --allow-empty -F - <<'EOF'
Record shell startup times

zsh: <before> -> <after> ms, bash: <before> -> <after> ms,
fish: <before> -> <after> ms (hyperfine, 20 runs, mean).

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

Replace the six `<...>` placeholders with the measured numbers from the two tables before running the command.

---

### Task 9: Delete the configs for systems no longer in use

**Files:**
- Delete: `bootstrap/macOS/`, `meta/configs/mac.conf.yaml`, `meta/configs/kali.conf.yaml`, `meta/configs/server.conf.yaml`, `etc/caddy/Caddyfile`, `etc/ssh/sshd_config`, `etc/dnscrypt-proxy/dnscrypt-proxy.toml.macos`, `etc/dnsmasq/dnsmasq.conf.macos`, `etc/privoxy/config.macos`, `etc/privoxy/user.action.macos`
- Modify: `install` (usage comment)

Kept on purpose: `meta/configs/{default,private,openwrt,windows}.conf.yaml`, `etc/privoxy/{config,default.action,user.action}`, `etc/dnscrypt-proxy/dnscrypt-proxy.toml`, `etc/ssh/ssh_config.d/`, `etc/NetworkManager/`, `etc/config/nut_monitor.openwrt`, `C/`, `bootstrap/Linux/`.

- [ ] **Step 1: Check what still references the files**

```bash
git grep -nE 'mac\.conf|kali\.conf|server\.conf|bootstrap/macOS|\.macos|Caddyfile|sshd_config' -- . ':!docs' ':!.gitmodules'
```

Expected: hits only in `install` (the usage comment) and possibly `README.md`; note them. Any hit in a file that stays (for example a config that copies a deleted file) must be fixed in Step 3.

- [ ] **Step 2: Delete**

```bash
git rm -r bootstrap/macOS \
    meta/configs/mac.conf.yaml meta/configs/kali.conf.yaml meta/configs/server.conf.yaml \
    etc/caddy etc/ssh/sshd_config \
    etc/dnscrypt-proxy/dnscrypt-proxy.toml.macos etc/dnsmasq/dnsmasq.conf.macos \
    etc/privoxy/config.macos etc/privoxy/user.action.macos
```

Expected: a list of removed files and no error.

- [ ] **Step 3: Fix the references from Step 1**

Edit `install`, replace:

```bash
# Use with `./install mac work`
```

with:

```bash
# Use with `./install private`
```

Fix any other hit from Step 1 in files outside `docs/` the same way (point the reference at a config that still exists, or remove it).

- [ ] **Step 4: Verify nothing dangles**

```bash
git grep -nE 'mac\.conf|kali\.conf|server\.conf|bootstrap/macOS|\.macos|Caddyfile|sshd_config' -- . ':!docs' ':!.gitmodules' || echo "no dangling references"
git status --short
```

Expected: `no dangling references`; `git status` shows the deletions staged and ` M config/kak/plugins/plug.kak` unstaged.

- [ ] **Step 5: Commit**

```bash
git add install
git commit -F - <<'EOF'
Remove configs for unused systems

macOS, Kali and server setups, plus the macOS variants of the dnsmasq,
dnscrypt and privoxy configs. OpenWrt, privoxy, dnsmasq and dnscrypt
stay for the router and the personal desktop.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

## Self-review against the spec

| Spec item (migration steps 1 and 2) | Task |
|---|---|
| Measure zsh startup | 3, 8 |
| Delete Debian/grml paste and duplicate `compinit` | 6 (grml files stay until plan 2; `.zshrc.local` no longer duplicates them) |
| Fix or drop slow evals (`pipx`, `dircolors`, `rbenv`) | 6, 7 (pipx cached; dircolors and rbenv kept, guarded) |
| Parity checklist (PATH, XDG, aliases, history, colors) verified per shell | 2, 4, 5, 6, 7 |
| Delete dead configs (macOS, Kali, server, `.macos` variants) | 9 |
| Work values out of tracked files (guardrail) | 0 |
| z4h unpinned bootstrap, auto-update | partly: auto-update off (6); removal is plan 2 |

Not covered here on purpose, left for the next plans: prompt parity (starship in all three shells), fzf bindings parity, mise/uv, chezmoi layout, `system/` tree, Windows `upall`, Linux dnsmasq config and dnscrypt blocklist.

## Notes for plan 2

- z4h runs `cmd.exe /c set` (a Windows-side process that dumps the Windows environment) on every zsh start, in `-z4h-init-wsl`, to find the Windows home for the `~w` shortcut. It adds to startup time and is visible to endpoint monitoring. z4h has no switch for it. Removing z4h removes it; `hash -d w=...` becomes a static path.
- `z` (directory jumping) is currently z.lua, loaded by z4h in zsh only. bash has no `z`, and fish only has it if the `jethrokuan/z` fisher plugin is installed. Plan 2 replaces it with zoxide in all three shells (see the spec): install zoxide and a current fzf (`zi` needs fzf 0.51 or newer, the z4h one is 0.33) through mise, run `zoxide import z.lua "$_ZL_DATA"` once, add `z` to the parity test, then drop `_ZL_DATA` from `profile` and fish.
- Removing z4h also removes what it provides: the login shell `/usr/local/bin/zsh` (a root-owned musl build, `/usr/bin/zsh` does not exist; check `bootstrap/Linux/install-zsh.sh`) and `fzf` (comes from `~/.cache/zsh4humans/v5/fzf`). Plan 2 must install zsh and fzf from a supported source and `chsh` back before z4h goes.
- The asdf blocks in all three shells (including the second `compinit` in zsh) disappear with the mise migration.
- Consider `.chezmoiroot` (`home/`) so that `docs/`, `tests/` and `system/` stay out of the chezmoi source tree without a long `.chezmoiignore`. Add it to the spec before the skeleton task.
- `~/.config/shell/work.env` and `config/git/config.work` already sit at the paths chezmoi will render; `chezmoi add` must not be run on them.
- `config/kak/plugins/plug.kak` is still a dirty submodule pointer; the externals work replaces it.
