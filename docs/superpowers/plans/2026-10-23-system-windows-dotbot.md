# System Files, Router, Mozilla, Windows and Retiring dotbot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (this plan has user-gated steps) to implement it task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Everything dotbot still does is either handled by chezmoi, handled by a tested script, or deleted, and dotbot, its submodules and the old bootstrap files are gone.

**Architecture:** Files outside `$HOME` live in a `system/` tree that chezmoi never applies directly; a `run_after_` script installs them with `sudo` only when they differ, on machines that opted in. Files for one platform sit under `home/` and are switched on by data flags (`desktop`, `windows`) in `.chezmoiignore`. The router config is rendered on this machine from Proton Pass and uploaded over SSH by a script in `tools/`. Each piece has a test that runs without the real target (stub `pass-cli`/`ssh`/`scp`, fake Firefox profiles, a container with `sudo`, a scratch home with `windows=true`).

**Tech Stack:** chezmoi 2.73.3, bash/POSIX sh, awk, envsubst, jq, Docker (clean room), winget (Windows).

**Spec:** `docs/superpowers/specs/2026-10-22-dotfiles-chezmoi-design.md`, migration steps 5 and 6. Package lists and the quick-install tier are plan 2d.

---

## Decisions already made by the user

| Topic | Decision |
|---|---|
| dnscrypt-proxy | Delete its config (and dnsmasq, which the repo has no config for). |
| Router | `nut_monitor` is rendered locally with the UPS settings from Proton Pass (`pass-cli`), then uploaded with `scp` (rsync is fine too). The router has no Proton Pass. I cannot test the upload from here. |
| NetworkManager hardening | Personal Linux desktop only (not WSL). |
| `ssh_config.d` | Any Linux, WSL included. |
| privoxy | Its config is old and needs a redo; it stays out of the automation and out of `/etc` for now. |
| `requirements*.txt` | Deleted; the Python tools move to mise. |
| Firefox / Thunderbird overrides | Managed by chezmoi, applied to the profiles by a helper (the user will update the files from another computer later). |
| `bootstrap/Linux` (GNOME) | Deleted: the desktop is PopOS with COSMIC. COSMIC settings can be added later with `chezmoi add ~/.config/cosmic/...`. |
| Windows `upall` | Managed by chezmoi on Windows; winget only, no elevation, no Windows Update, no `decentsec`. I cannot test the Windows part from here. |

## Ground rules

- Branches `system-files` (Part 1) and `retire-dotbot` (Part 2), created with `git switch -c <name> origin/main`. Part 2 starts after Part 1 is merged.
- Preserve the user's content: files are moved with `git mv`; the only edit to a moved file is the quoting of the four placeholders in `nut_monitor` (Task 3).
- chezmoi runs templates with `missingkey=error`: a data key that is not in `~/.config/chezmoi/chezmoi.toml` is an error. After merging Task 1, every existing machine must run `chezmoi init` (it asks the two new questions) before the next `chezmoi apply`.
- Test in a scratch home or the clean-room container first; nothing touches the real home until the user-gated Task 9.
- Never print secrets. The router test uses fake credentials. `pass-cli` is not installed here, so the Proton Pass call is exercised only through a stub (the one unverified fact is the JSON shape of `pass-cli item view --field ... --output json`).
- No internal names in tracked files (`tests/denylist-check.sh` runs on commit). No `powershell.exe` or registry probing on this machine.
- Commits: short subject, then `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`; check `git config user.email`; if signing fails with a 1Password error ask the user to unlock it and retry, never skip signing.
- The Bash tool runs zsh: explicit lists, no word-splitting of unquoted variables; run scripts as files with `bash script.sh`.

## File structure

| Path | Action | Responsibility |
|---|---|---|
| `home/.chezmoi.toml.tmpl` | Modify | Two new prompts (`desktop`, `system_files`) and computed `windows`. |
| `home/.chezmoiignore` | Modify | Desktop-only and Windows-only switches. |
| `system/linux/etc/ssh/ssh_config.d/default.conf` | Move | Installed on any Linux that opted in. |
| `system/linux-desktop/etc/NetworkManager/conf.d/*.conf` | Move | Installed on desktops that opted in. |
| `system/openwrt/nut_monitor` | Move + edit | Router template with four placeholders. |
| `home/.chezmoiscripts/run_after_10-system-files.sh.tmpl` | Create | Installs `system/linux*` into `/etc`. |
| `tools/deploy-router.sh` | Create | Renders and uploads the router config. |
| `tests/deploy-router-test.sh` | Create | Tests it with stub `pass-cli`, `ssh`, `scp`. |
| `home/dot_config/mozilla-overrides/*` | Move | The three override files. |
| `home/dot_local/bin/executable_mozilla-apply-overrides` | Create | Copies them into the profiles. |
| `home/.chezmoiscripts/run_onchange_after_20-mozilla-overrides.sh.tmpl` | Create | Runs the helper when the override files change. |
| `tests/mozilla-overrides-test.sh` | Create | Tests the helper with fake profiles. |
| `home/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/upall.cmd` | Create | Windows logon updater (winget). |
| `.gitattributes` | Create | CRLF for `.cmd`. |
| `home/dot_config/mise/config.toml.tmpl` | Modify | Python tools. |
| `extras/privoxy/` | Move | Old privoxy config, not installed. |
| `meta/`, `install`, `.gitmodules`, `bootstrap/`, `C/`, `mozilla/`, `requirements*.txt`, `etc/` | Delete | Retired. |
| `tests/clean-room.sh` | Modify | `sudo`, `openssh-client`, system files, the two new tests. |

---

## Part 1: data flags, system files, router, Mozilla

### Task 1: Data flags and ignore rules

**Files:**
- Modify: `home/.chezmoi.toml.tmpl`, `home/.chezmoiignore`

- [ ] **Step 1: Branch and scratch helper**

```bash
cd /home/alex/src/dotfiles
git switch -c system-files origin/main
```

Update `/tmp/run-scratch.sh` so its generated config has the new keys (otherwise `missingkey=error` stops the apply). Its `printf` line becomes:

```bash
printf 'sourceDir = "/home/alex/src/dotfiles"\n[data]\n    work = false\n    wsl = false\n    desktop = %s\n    system_files = false\n    windows = %s\n' "${DESKTOP:-false}" "${WINDOWS:-false}" >/tmp/scratch-chezmoi.toml
```

- [ ] **Step 2: The config template**

Edit `home/.chezmoi.toml.tmpl`, replace:

```
{{- $work := promptBoolOnce . "work" "Is this a work machine" false -}}
{{- $wsl := false -}}
```

with:

```
{{- $work := promptBoolOnce . "work" "Is this a work machine" false -}}
{{- $desktop := false -}}
{{- $system := false -}}
{{- if eq .chezmoi.os "linux" -}}
{{-   $desktop = promptBoolOnce . "desktop" "Does this machine have a desktop environment (not WSL)" false -}}
{{-   $system = promptBoolOnce . "system_files" "Install system files under /etc (needs sudo)" false -}}
{{- end -}}
{{- $wsl := false -}}
```

Edit the same file, replace:

```
    work = {{ $work }}
    wsl = {{ $wsl }}
```

with:

```
    work = {{ $work }}
    desktop = {{ $desktop }}
    system_files = {{ $system }}
    wsl = {{ $wsl }}
    windows = {{ eq .chezmoi.os "windows" }}
```

- [ ] **Step 3: The ignore rules**

Replace the whole of `home/.chezmoiignore` with:

```
{{ if .wsl }}
.config/autostart
.config/conky
.config/glava
.config/mozc
{{ end }}
{{ if not .desktop }}
.config/mozilla-overrides
.local/bin/mozilla-apply-overrides
{{ end }}
{{ if .windows }}
**
!AppData
!AppData/**
{{ else }}
AppData
{{ end }}
```

(`!` patterns win over the `**` ignore, per the chezmoi docs. On Windows only `AppData` is applied for now.)

- [ ] **Step 4: Render and check**

```bash
chezmoi execute-template --init --promptDefaults --source /home/alex/src/dotfiles < home/.chezmoi.toml.tmpl
```

Expected: `[data]` now has `work`, `desktop`, `system_files`, `wsl` and `windows = false`, all false except `wsl = true` on this machine.

- [ ] **Step 5: Commit**

```bash
git add home/.chezmoi.toml.tmpl home/.chezmoiignore
git commit -F - <<'EOF'
chezmoi data: desktop, system_files, windows; ignore rules

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

(Existing machines need `chezmoi init` before the next apply; do not apply yet.)

---

### Task 2: The `system/` tree and its installer

**Files:**
- Move: `etc/ssh/ssh_config.d/default.conf`, `etc/NetworkManager/conf.d/*`
- Create: `home/.chezmoiscripts/run_after_10-system-files.sh.tmpl`

- [ ] **Step 1: Move the files**

```bash
mkdir -p system/linux/etc/ssh/ssh_config.d system/linux-desktop/etc/NetworkManager/conf.d
git mv etc/ssh/ssh_config.d/default.conf system/linux/etc/ssh/ssh_config.d/default.conf
git mv etc/NetworkManager/conf.d/ip6-privacy.conf etc/NetworkManager/conf.d/wifi_rand_mac.conf system/linux-desktop/etc/NetworkManager/conf.d/
git ls-files system | cat
```

- [ ] **Step 2: The installer script**

Write `home/.chezmoiscripts/run_after_10-system-files.sh.tmpl`:

```
{{- if and .system_files (eq .chezmoi.os "linux") -}}
#!/usr/bin/env bash
# Install the files under system/ into /etc. Runs on every apply, but sudo is only
# used for a file that differs from the installed one.
set -euo pipefail

src={{ printf "%s/system" .chezmoi.workingTree | quote }}
sudo=sudo
[ "$(id -u)" -eq 0 ] && sudo=

changed_nm=0
install_tree() { # $1 = directory under system/ that mirrors /
    local tree=$1 f dest
    [ -d "$src/$tree" ] || return 0
    while IFS= read -r -d '' f; do
        dest=${f#"$src/$tree"}
        if ! cmp -s "$f" "$dest"; then
            echo "installing $dest"
            $sudo install -D -m 0644 -o root -g root "$f" "$dest"
            case $dest in /etc/NetworkManager/*) changed_nm=1 ;; esac
        fi
    done < <(find "$src/$tree" -type f -print0)
}

install_tree linux
{{ if .desktop -}}
install_tree linux-desktop
{{ end -}}
if [ "$changed_nm" -eq 1 ] && command -v nmcli >/dev/null 2>&1; then
    $sudo nmcli general reload conf || true
fi
{{ end -}}
```

- [ ] **Step 3: Render and lint the rendered script**

```bash
cat > /tmp/data.json <<'EOF'
{"system_files": true, "desktop": true}
EOF
chezmoi execute-template --override-data "$(cat /tmp/data.json)" --source /home/alex/src/dotfiles < home/.chezmoiscripts/run_after_10-system-files.sh.tmpl > /tmp/rendered-system.sh
shellcheck /tmp/rendered-system.sh && bash -n /tmp/rendered-system.sh && echo "rendered script ok"
chezmoi execute-template --override-data '{"system_files": false, "desktop": false}' --source /home/alex/src/dotfiles < home/.chezmoiscripts/run_after_10-system-files.sh.tmpl | wc -c
```

Expected: `rendered script ok`, and `0` bytes when `system_files` is false (chezmoi skips an empty script). If shellcheck reports `SC2086` for `$sudo`, add `# shellcheck disable=SC2086` above those two lines in the template; the unquoted expansion is intended (empty when root).

- [ ] **Step 4: Commit**

```bash
git add -A system home/.chezmoiscripts etc
git commit -F - <<'EOF'
Add system/ tree and an installer for the files under /etc

ssh_config.d for any Linux that opts in, NetworkManager hardening for
desktops. sudo is only used for files that differ.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 3: Router config and deploy script

**Files:**
- Move: `etc/config/nut_monitor.openwrt` to `system/openwrt/nut_monitor`
- Create: `tools/deploy-router.sh`, `tests/deploy-router-test.sh`

- [ ] **Step 1: Move the template and quote the placeholders**

```bash
mkdir -p system/openwrt tools
git mv etc/config/nut_monitor.openwrt system/openwrt/nut_monitor
```

Edit `system/openwrt/nut_monitor`: the four lines

```
	option upsname $UPSNAME
	option hostname $UPS_HOSTNAME
	option username $UPS_USERNAME
	option password $UPS_PASSWORD
```

become (a UCI value in single quotes may contain spaces; the script rejects values with a single quote or a newline):

```
	option upsname '$UPSNAME'
	option hostname '$UPS_HOSTNAME'
	option username '$UPS_USERNAME'
	option password '$UPS_PASSWORD'
```

- [ ] **Step 2: The deploy script**

Write `tools/deploy-router.sh`:

```bash
#!/usr/bin/env bash
# Render system/openwrt/nut_monitor with the UPS settings from Proton Pass and upload
# it to the router over SSH. The router has no pass-cli, so the secrets are filled in
# here, on this machine, and never written anywhere but a private temporary directory.
#
# Usage: tools/deploy-router.sh [--dry-run] [--restart] <ssh-host>
#   <ssh-host>  host alias from ~/.ssh/config
#   --dry-run   render and check, print a masked copy, upload nothing
#   --restart   restart the nut-monitor service on the router afterwards
#
# Proton Pass item (override with PASS_VAULT / PASS_ITEM): vault "Personal", title
# "router-ups", fields upsname, hostname, username, password.
# Needs pass-cli (logged in, or PROTON_PASS_PAT set), envsubst, jq, ssh, scp.
# SCP_OPTS defaults to -O (legacy protocol, for routers with Dropbear and no sftp-server).

set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
template=$repo/system/openwrt/nut_monitor
pass_cli=${PASS_CLI:-pass-cli}
vault=${PASS_VAULT:-Personal}
item=${PASS_ITEM:-router-ups}
scp_opts=${SCP_OPTS:--O}

dry_run=0
restart=0
host=
while [ $# -gt 0 ]; do
    case $1 in
        --dry-run) dry_run=1 ;;
        --restart) restart=1 ;;
        -h | --help)
            sed -n '2,15p' "$0"
            exit 0
            ;;
        -*)
            echo "unknown option: $1" >&2
            exit 2
            ;;
        *) host=$1 ;;
    esac
    shift
done
[ -n "$host" ] || {
    echo "usage: $0 [--dry-run] [--restart] <ssh-host>" >&2
    exit 2
}

# Print the value of one field of the Proton Pass item; fail loudly on anything odd.
field() {
    local out
    out=$("$pass_cli" item view --vault-name "$vault" --item-title "$item" --field "$1" --output json) || {
        echo "pass-cli failed for field '$1' of '$item' in vault '$vault'" >&2
        exit 1
    }
    out=$(printf '%s' "$out" | jq -r 'if type == "string" then . else (.value // empty) end')
    if [ -z "$out" ]; then
        echo "no usable value for field '$1' (unexpected pass-cli output shape?)" >&2
        exit 1
    fi
    case $out in
        *\'* | *$'\n'*)
            echo "field '$1' contains a single quote or a newline, which the UCI file cannot hold" >&2
            exit 1
            ;;
    esac
    printf '%s' "$out"
}

umask 077
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

UPSNAME=$(field upsname)
UPS_HOSTNAME=$(field hostname)
UPS_USERNAME=$(field username)
UPS_PASSWORD=$(field password)
export UPSNAME UPS_HOSTNAME UPS_USERNAME UPS_PASSWORD

envsubst '$UPSNAME $UPS_HOSTNAME $UPS_USERNAME $UPS_PASSWORD' <"$template" >"$tmp/nut_monitor"

if grep -qE '\$(UPSNAME|UPS_HOSTNAME|UPS_USERNAME|UPS_PASSWORD)' "$tmp/nut_monitor"; then
    echo "a placeholder is still unfilled in the rendered file" >&2
    exit 1
fi

if [ "$dry_run" -eq 1 ]; then
    echo "rendered OK ($(wc -l <"$tmp/nut_monitor") lines). Masked copy:"
    sed -E "s/^(\s*option (upsname|hostname|username|password) ).*/\1'<filled>'/" "$tmp/nut_monitor"
    exit 0
fi

remote_tmp=/tmp/nut_monitor.new
# shellcheck disable=SC2086
scp $scp_opts -q "$tmp/nut_monitor" "$host:$remote_tmp"
ssh "$host" "chmod 600 $remote_tmp && { [ -f /etc/config/nut_monitor ] && cp -a /etc/config/nut_monitor /etc/config/nut_monitor.bak || true; } && mv $remote_tmp /etc/config/nut_monitor"
echo "uploaded to $host:/etc/config/nut_monitor (previous copy kept as nut_monitor.bak)"
if [ "$restart" -eq 1 ]; then
    ssh "$host" '/etc/init.d/nut-monitor restart'
fi
```

- [ ] **Step 3: The test (stub `pass-cli`, `ssh`, `scp`)**

Write `tests/deploy-router-test.sh`:

```bash
#!/usr/bin/env bash
# Test tools/deploy-router.sh with stub pass-cli, ssh and scp. Nothing leaves this machine.
set -u

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/log"
fail=0
check() { # description, command...
    local desc=$1
    shift
    if "$@"; then echo "ok   $desc"; else echo "FAIL $desc"; fail=1; fi
}

# stub pass-cli: field values, one of them in the object shape
cat >"$work/bin/pass-cli" <<'EOF'
#!/bin/sh
case "$*" in
    *"--field upsname"*) echo '"my ups"' ;;
    *"--field hostname"*) echo '{"value": "192.0.2.10"}' ;;
    *"--field username"*) echo '"monuser"' ;;
    *"--field password"*) echo "\"${STUB_PASSWORD:-s3cret-Pw}\"" ;;
    *) echo "unexpected: $*" >&2; exit 1 ;;
esac
EOF
# stub scp keeps a copy of what would be uploaded; stub ssh logs its command
cat >"$work/bin/scp" <<EOF
#!/bin/sh
echo "\$*" >"$work/log/scp.args"
for last; do :; done
src=""
for a; do case \$a in -*) ;; *:*) ;; *) src=\$a ;; esac; done
cp "\$src" "$work/log/uploaded"
stat -c %a "\$src" >"$work/log/uploaded.mode"
EOF
cat >"$work/bin/ssh" <<EOF
#!/bin/sh
echo "\$*" >>"$work/log/ssh.args"
EOF
chmod +x "$work/bin/"*

run() { PATH="$work/bin:$PATH" PASS_CLI="$work/bin/pass-cli" "$repo/tools/deploy-router.sh" "$@"; }

# 1. dry run: exits 0, shows no secret, uploads nothing
out=$(run --dry-run router 2>&1)
check "dry run succeeds" test $? -eq 0
check "dry run output contains no secret" bash -c '! printf "%s" "$1" | grep -qE "s3cret-Pw|monuser|192.0.2.10|my ups"' _ "$out"
check "dry run masks the four options" bash -c 'printf "%s" "$1" | grep -c "<filled>" | grep -qx 4' _ "$out"
check "dry run does not upload" test ! -e "$work/log/scp.args"

# 2. real run: uploads a filled, private file and installs it with a backup
run --restart router >/dev/null 2>&1
check "real run succeeds" test $? -eq 0
check "scp used the legacy protocol and the router" grep -q -- '-O -q .* router:/tmp/nut_monitor.new' "$work/log/scp.args"
check "uploaded file has the values" bash -c 'grep -q "option password .s3cret-Pw." "$1" && grep -q "option hostname .192.0.2.10." "$1" && grep -q "option upsname .my ups." "$1"' _ "$work/log/uploaded"
check "uploaded file has no placeholder left" bash -c '! grep -qE "\$(UPSNAME|UPS_)" "$1"' _ "$work/log/uploaded"
check "uploaded file was private (600)" grep -qx 600 "$work/log/uploaded.mode"
check "ssh installs with chmod 600 and a backup" grep -q 'chmod 600 /tmp/nut_monitor.new.*nut_monitor.bak.*mv /tmp/nut_monitor.new /etc/config/nut_monitor' "$work/log/ssh.args"
check "restart ran" grep -q '/etc/init.d/nut-monitor restart' "$work/log/ssh.args"

# 3. refuses a value UCI cannot hold
rm -f "$work/log/scp.args"
STUB_PASSWORD="it's" run router >/dev/null 2>&1
check "a password with a single quote is rejected" test $? -ne 0
check "nothing uploaded after the rejection" test ! -e "$work/log/scp.args"

# 4. missing argument and unknown option
run >/dev/null 2>&1
check "no host is a usage error" test $? -eq 2
run --bogus router >/dev/null 2>&1
check "unknown option is a usage error" test $? -eq 2

exit $fail
```

- [ ] **Step 4: Run it and lint**

```bash
chmod +x tools/deploy-router.sh tests/deploy-router-test.sh
shellcheck tools/deploy-router.sh tests/deploy-router-test.sh && shfmt -i 4 -bn -ci -d tools/deploy-router.sh tests/deploy-router-test.sh && echo "lint ok"
bash tests/deploy-router-test.sh
```

Expected: `lint ok` and every line `ok ...`. Fix the script, not the test, when a check fails. If `shfmt` reformats the heredocs differently, run `shfmt -i 4 -bn -ci -w` on both files and rerun.

- [ ] **Step 5: Add `tools` to the pre-commit scopes**

Edit `.pre-commit-config.yaml`: change both `files: ^tests/` lines (shellcheck and shfmt) to `files: ^(tests|tools)/`.

- [ ] **Step 6: Commit**

```bash
pre-commit run --all-files
git add -A system tools tests .pre-commit-config.yaml etc
git commit -F - <<'EOF'
Add the router deploy script with a stub-based test

Renders the OpenWrt nut_monitor template from Proton Pass on this
machine and uploads it with scp. Values with a single quote or a newline
are refused; a backup is kept on the router.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 4: Firefox and Thunderbird overrides

**Files:**
- Move: `mozilla/firefox/user-overrides.js`, `mozilla/firefox/user-overrides-dev.js`, `mozilla/thunderbird/user.js`
- Create: `home/dot_local/bin/executable_mozilla-apply-overrides`, `home/.chezmoiscripts/run_onchange_after_20-mozilla-overrides.sh.tmpl`, `tests/mozilla-overrides-test.sh`

- [ ] **Step 1: Move the three files**

```bash
mkdir -p home/dot_config/mozilla-overrides
git mv mozilla/firefox/user-overrides.js home/dot_config/mozilla-overrides/firefox-user-overrides.js
git mv mozilla/firefox/user-overrides-dev.js home/dot_config/mozilla-overrides/firefox-user-overrides-dev.js
git mv mozilla/thunderbird/user.js home/dot_config/mozilla-overrides/thunderbird-user.js
```

- [ ] **Step 2: The helper**

Write `home/dot_local/bin/executable_mozilla-apply-overrides`:

```sh
#!/bin/sh
# Copy the managed override files into the Firefox and Thunderbird profiles.
#   Firefox: a profile whose name contains "dev" gets firefox-user-overrides-dev.js,
#            every other profile gets firefox-user-overrides.js (both as user-overrides.js).
#   Thunderbird: every profile gets thunderbird-user.js (as user.js).
# user-overrides.js is read by the arkenfox/ghacks updater.sh: run it afterwards to merge.
# Usage: mozilla-apply-overrides [-n]    (-n shows what would be copied)
set -eu

src=${XDG_CONFIG_HOME:-$HOME/.config}/mozilla-overrides
dry=0
[ "${1:-}" = "-n" ] && dry=1
tab=$(printf '\t')

# $1 = directory with a profiles.ini; prints "name<TAB>absolute path" per profile
profiles() {
    [ -r "$1/profiles.ini" ] || return 0
    awk -v base="$1" '
        function flush() {
            if (path != "") print name "\t" (rel == "1" ? base "/" path : path)
            name = ""; path = ""; rel = "1"
        }
        BEGIN { rel = "1" }
        /^\[/ { flush(); insec = ($0 ~ /^\[Profile/); next }
        insec && /^Name=/ { name = substr($0, 6) }
        insec && /^Path=/ { path = substr($0, 6) }
        insec && /^IsRelative=/ { rel = substr($0, 12) }
        END { flush() }
    ' "$1/profiles.ini"
}

copy() { # $1 = source file, $2 = destination file
    if [ ! -r "$1" ]; then
        echo "missing $1" >&2
        return 0
    fi
    if [ "$dry" -eq 1 ]; then
        echo "would copy $1 -> $2"
    else
        cp -f "$1" "$2" && echo "copied $1 -> $2"
    fi
}

for dir in "$HOME/.mozilla/firefox" \
    "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox" \
    "$HOME/snap/firefox/common/.mozilla/firefox"; do
    profiles "$dir" | while IFS="$tab" read -r name path; do
        [ -d "$path" ] || continue
        case $name in
            *dev* | *Dev*) copy "$src/firefox-user-overrides-dev.js" "$path/user-overrides.js" ;;
            *) copy "$src/firefox-user-overrides.js" "$path/user-overrides.js" ;;
        esac
    done
done

for dir in "$HOME/.thunderbird" \
    "$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird" \
    "$HOME/snap/thunderbird/common/.thunderbird"; do
    profiles "$dir" | while IFS="$tab" read -r _ path; do
        [ -d "$path" ] || continue
        copy "$src/thunderbird-user.js" "$path/user.js"
    done
done
```

- [ ] **Step 3: The test (fake profiles in a temporary home)**

Write `tests/mozilla-overrides-test.sh`:

```bash
#!/usr/bin/env bash
# Test home/dot_local/bin/executable_mozilla-apply-overrides against fake profiles.
set -u

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
helper=$repo/home/dot_local/bin/executable_mozilla-apply-overrides
home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
fail=0
check() {
    local desc=$1
    shift
    if "$@"; then echo "ok   $desc"; else echo "FAIL $desc"; fail=1; fi
}

mkdir -p "$home/.config/mozilla-overrides"
echo "std"  >"$home/.config/mozilla-overrides/firefox-user-overrides.js"
echo "dev"  >"$home/.config/mozilla-overrides/firefox-user-overrides-dev.js"
echo "tb"   >"$home/.config/mozilla-overrides/thunderbird-user.js"

# a deb-style Firefox with a default and a dev profile, a relative and an absolute path
mkdir -p "$home/.mozilla/firefox/abc.default-release" "$home/.mozilla/firefox/xyz.dev-edition" "$home/elsewhere"
cat >"$home/.mozilla/firefox/profiles.ini" <<EOF
[Install1234]
Default=abc.default-release

[Profile2]
Name=dev-edition
IsRelative=1
Path=xyz.dev-edition

[Profile0]
Name=default-release
IsRelative=1
Path=abc.default-release

[Profile1]
Name=other
IsRelative=0
Path=$home/elsewhere

[General]
StartWithLastProfile=1
EOF
# a Flatpak Thunderbird
mkdir -p "$home/.var/app/org.mozilla.Thunderbird/.thunderbird/tb.default"
cat >"$home/.var/app/org.mozilla.Thunderbird/.thunderbird/profiles.ini" <<EOF
[Profile0]
Name=default
IsRelative=1
Path=tb.default
EOF

HOME=$home XDG_CONFIG_HOME=$home/.config sh "$helper" -n >"$home/dry.out"
check "dry run copies nothing" test ! -e "$home/.mozilla/firefox/abc.default-release/user-overrides.js"
check "dry run lists three Firefox profiles and one Thunderbird" bash -c '[ "$(grep -c "would copy" "$1")" -eq 4 ]' _ "$home/dry.out"

HOME=$home XDG_CONFIG_HOME=$home/.config sh "$helper" >/dev/null
check "default profile gets the standard file" grep -qx std "$home/.mozilla/firefox/abc.default-release/user-overrides.js"
check "dev profile gets the dev file" grep -qx dev "$home/.mozilla/firefox/xyz.dev-edition/user-overrides.js"
check "absolute-path profile gets the standard file" grep -qx std "$home/elsewhere/user-overrides.js"
check "Flatpak Thunderbird gets user.js" grep -qx tb "$home/.var/app/org.mozilla.Thunderbird/.thunderbird/tb.default/user.js"

# no profiles at all is fine
empty=$(mktemp -d)
HOME=$empty XDG_CONFIG_HOME=$empty/.config sh "$helper" >/dev/null 2>&1
check "no Mozilla install is not an error" test $? -eq 0
rm -rf "$empty"

exit $fail
```

- [ ] **Step 4: Run and lint**

```bash
chmod +x home/dot_local/bin/executable_mozilla-apply-overrides tests/mozilla-overrides-test.sh
shellcheck -s sh home/dot_local/bin/executable_mozilla-apply-overrides && shellcheck tests/mozilla-overrides-test.sh && shfmt -i 4 -bn -ci -d home/dot_local/bin/executable_mozilla-apply-overrides tests/mozilla-overrides-test.sh && echo "lint ok"
bash tests/mozilla-overrides-test.sh
```

Expected: `lint ok` and every check `ok`. If `shfmt` rewrites the aligned `echo "std"  >` lines, run it with `-w` and rerun.

- [ ] **Step 5: The apply hook**

Write `home/.chezmoiscripts/run_onchange_after_20-mozilla-overrides.sh.tmpl`:

```
{{- if .desktop -}}
#!/bin/sh
# Runs when an override file changes. Hashes: {{ include "dot_config/mozilla-overrides/firefox-user-overrides.js" | sha256sum }} {{ include "dot_config/mozilla-overrides/firefox-user-overrides-dev.js" | sha256sum }} {{ include "dot_config/mozilla-overrides/thunderbird-user.js" | sha256sum }}
"$HOME/.local/bin/mozilla-apply-overrides"
{{ end -}}
```

Render check: `chezmoi execute-template --override-data '{"desktop": true}' --source /home/alex/src/dotfiles < home/.chezmoiscripts/run_onchange_after_20-mozilla-overrides.sh.tmpl | head -3` shows three hashes; with `desktop` false it prints nothing.

- [ ] **Step 6: Widen the pre-commit scope and commit**

Edit `.pre-commit-config.yaml`: make both shell hooks' `files:` regex `^(tests|tools)/|^home/dot_local/bin/executable_(clipcopy|clippaste|copypath|mozilla-apply-overrides)$`.

```bash
pre-commit run --all-files
git add -A home tests .pre-commit-config.yaml mozilla
git commit -F - <<'EOF'
Manage the Firefox and Thunderbird overrides with chezmoi

A helper copies them into every profile found through profiles.ini
(deb, Flatpak and snap locations); chezmoi runs it when a file changes.
Desktop machines only.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 5: Extend the clean room and test the ignore rules

**Files:**
- Modify: `tests/clean-room.sh`

- [ ] **Step 1: Container changes**

Edit `tests/clean-room.sh`:
- add `sudo openssh-client gettext-base jq` to the `apt-get install` list;
- after `useradd`, add `echo 'tester ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/tester`;
- in the generated `run.sh`, change the `chezmoi init` line to answer the two new questions (the prompt texts must match `home/.chezmoi.toml.tmpl` exactly):

```bash
chezmoi init --source ~/dotfiles --promptDefaults \
    --promptBool 'Does this machine have a desktop environment (not WSL)=true' \
    --promptBool 'Install system files under /etc (needs sudo)=true' \
    --apply --exclude=scripts
chezmoi apply --include=scripts
```

(the first apply skips scripts like before, the second runs only the scripts: it installs the system files and, because `desktop` is true, runs the Mozilla hook against no profiles.) Then add, after the zsh smoke test:

```bash
echo "--- system files"
test -f /etc/ssh/ssh_config.d/default.conf
test -f /etc/NetworkManager/conf.d/ip6-privacy.conf
ssh -G example.com | grep -qix 'identitiesonly yes'
echo "ok"
echo "--- script tests"
bash ~/dotfiles/tests/deploy-router-test.sh
bash ~/dotfiles/tests/mozilla-overrides-test.sh
```

If `--promptBool` does not combine with `--promptDefaults` (the first run prompts or fails), drop `--promptDefaults` and give all three prompts explicitly (`Is this a work machine=false` too).

- [ ] **Step 2: Run it**

```bash
shellcheck tests/clean-room.sh && shfmt -i 4 -bn -ci -d tests/clean-room.sh && echo "lint ok"
timeout 1200 tests/clean-room.sh 2>&1 | tail -30
```

Expected: `PASS zsh`, `PASS fish`, `SMOKE-OK`, then the system-files lines and every check of both script tests `ok`.

- [ ] **Step 3: The ignore rules for Windows and non-desktop, in a scratch home**

```bash
EXCLUDE=scripts,externals bash /tmp/run-scratch.sh /tmp/scratch-home
test ! -e /tmp/scratch-home/.config/mozilla-overrides && echo "no overrides on a non-desktop"
test ! -e /tmp/scratch-home/AppData && echo "no AppData on Linux"
DESKTOP=true EXCLUDE=scripts,externals bash /tmp/run-scratch.sh /tmp/scratch-home
test -f /tmp/scratch-home/.config/mozilla-overrides/firefox-user-overrides.js && echo "overrides on a desktop"
```

The Windows case is checked after Task 6, when `AppData` has a file in it.

- [ ] **Step 4: Commit**

```bash
git add tests/clean-room.sh
git commit -F - <<'EOF'
Clean room: system files with sudo, router and Mozilla tests

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
git push -u origin system-files
```

The user opens the PR for Part 1.

---

## Part 2: Windows, mise Python tools, retiring dotbot

Start after Part 1 is merged: `git switch -c retire-dotbot origin/main`.

### Task 6: Windows `upall`

**Files:**
- Create: `home/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/upall.cmd`, `.gitattributes`
- Delete: `C/`

- [ ] **Step 1: The script**

Write `home/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/upall.cmd`:

```bat
@echo off
rem Runs at logon (Startup folder). winget only: no elevation, no Windows Update
rem (the organisation's update policy owns that), no Chocolatey, no pause.
rem Relaunch minimised so no console window stays in the way.
if not "%~1"=="min" (
    start "" /min "%~f0" min
    exit /b
)
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --disable-interactivity >"%LOCALAPPDATA%\upall.log" 2>&1
```

Write `.gitattributes`:

```
*.cmd text eol=crlf
```

- [ ] **Step 2: Remove the old Windows scripts**

```bash
git rm -rq C
```

- [ ] **Step 3: Test the ignore rules with `windows=true` (cannot run Windows from here)**

```bash
WINDOWS=true EXCLUDE=scripts bash /tmp/run-scratch.sh /tmp/scratch-home
find /tmp/scratch-home -mindepth 1 -maxdepth 2 | sed "s#/tmp/scratch-home/##" | sort
test -f "/tmp/scratch-home/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/upall.cmd" && echo "upall.cmd applied"
file "/tmp/scratch-home/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/upall.cmd"
bash /tmp/run-scratch.sh /tmp/scratch-home >/dev/null 2>&1; test ! -e /tmp/scratch-home/AppData && echo "no AppData on Linux"
```

Expected with `windows=true`: only `AppData/...` exists in the scratch home (no `.config`, `.profile`, `.local`), `upall.cmd applied`, and `file` reports CRLF line terminators. Expected afterwards on Linux: `no AppData on Linux`.

- [ ] **Step 4: Commit**

```bash
git add -A home .gitattributes C
git commit -F - <<'EOF'
Windows: winget-only upall as a managed Startup file

Replaces the elevated upall and decentsec scripts. chezmoi on Windows
applies only AppData; Linux machines ignore it.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 7: Python tools through mise; delete `requirements*.txt`

**Files:**
- Modify: `home/dot_config/mise/config.toml.tmpl`
- Delete: `requirements.txt`, `requirements-pipx.txt`

- [ ] **Step 1: Ask which tools to keep**

The old lists were `pipx`, `ansito`, `black`, `jedi`, `mypy`, `proselint` (`fawkes`, `ialauncher`, `youtube-dl` commented out). Ask the user which of `black`, `mypy`, `proselint`, `jedi`, `ansito` they still use and whether they belong on every machine or only the work/personal ones. `pipx` itself is not needed (mise uses uv). Do not add a tool the user did not confirm.

- [ ] **Step 2: Pin and add the confirmed ones**

For each confirmed tool `<t>`: `~/.local/bin/mise latest "pipx:<t>"` gives the version. Add to `home/dot_config/mise/config.toml.tmpl` (in the shared block, or inside `{{ if .work }}` / `{{ if not .work }}` as the user said), for example:

```toml
"pipx:black" = "<version printed>"
```

A literal `<version printed>` must never be committed: check with `grep -c '<version' home/dot_config/mise/config.toml.tmpl`, which must print `0`.

- [ ] **Step 3: Install in the scratch home and check**

```bash
EXCLUDE=scripts,externals bash /tmp/run-scratch.sh /tmp/scratch-home
cd /tmp/scratch-home && HOME=/tmp/scratch-home XDG_CONFIG_HOME=/tmp/scratch-home/.config XDG_DATA_HOME=/tmp/scratch-home/.local/share XDG_CACHE_HOME=/tmp/scratch-home/.cache /home/alex/.local/bin/mise install 2>&1 | tail -5
```

Expected: the tools install under the scratch home. Then `git rm -q requirements.txt requirements-pipx.txt`.

- [ ] **Step 4: Commit**

```bash
git add -A home requirements.txt requirements-pipx.txt
git commit -F - <<'EOF'
Python tools through mise; drop requirements files

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 8: Retire dotbot and the old files

**Files:**
- Delete: `meta/`, `install`, `.gitmodules`, `bootstrap/`, `etc/dnscrypt-proxy/`
- Move: `etc/privoxy/` to `extras/privoxy/`
- Modify: `README.md`, `.github/` (none expected)

- [ ] **Step 1: See what is left**

```bash
git ls-files | grep -vE '^(home|docs|tests|tools|system|\.github)/' | cat
```

Expected (before this task): `.chezmoiroot`, `.gitignore`, `.gitattributes`, `.gitleaksignore`, `.gitmodules`, `.pre-commit-config.yaml`, `LICENSE`, `README.md`, `install`, `meta/...`, `bootstrap/...`, `etc/dnscrypt-proxy/...`, `etc/privoxy/...`.

- [ ] **Step 2: Remove and move**

```bash
mkdir -p extras
git mv etc/privoxy extras/privoxy
git rm -rq meta install .gitmodules bootstrap etc/dnscrypt-proxy
rm -rf etc .git/modules 2>/dev/null || true
git submodule status | wc -l
git ls-files | grep -E '^(meta|install|bootstrap|etc|C|mozilla)(/|$)' | wc -l
```

Expected: `0` submodules and `0` leftover paths. (`rm -rf .git/modules` only clears dotbot's local clones.)

- [ ] **Step 3: README**

Read `README.md`. Keep every existing line. Change the `## Install` section to also mention the optional `system_files` and `desktop` answers, add a short `## Layout` table (`home/` chezmoi source, `system/` files for `/etc` and the router, `tools/` scripts, `tests/` checks, `extras/` old files not applied), and add a Windows paragraph: install chezmoi with `winget install twpayne.chezmoi`, `chezmoi init --apply cyberflamingo/dotfiles`, answer `false` to the Linux questions; only `AppData` is applied there.

- [ ] **Step 4: Verify everything still works**

```bash
pre-commit run --all-files
bash tests/deploy-router-test.sh && bash tests/mozilla-overrides-test.sh
timeout 1200 tests/clean-room.sh 2>&1 | tail -20
chezmoi verify 2>&1 | head -3
```

(`chezmoi verify` needs 1Password unlocked; use `chezmoi status --exclude=templates` otherwise.)

- [ ] **Step 5: Commit and push**

```bash
git add -A
git status --short | grep -v '^[DRM]' | cat
git commit -F - <<'EOF'
Retire dotbot and the old bootstrap files

meta/, install, the submodules, GNOME bootstrap, dnscrypt-proxy config
and the Windows scripts are gone. The old privoxy config is kept under
extras/ (not installed) until it is redone.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
EOF
git push -u origin retire-dotbot
```

---

### Task 9: Live steps (user-gated, each needs the user's go)

- [ ] **This machine (WSL work laptop):** after Part 1 is merged, `git switch main && git merge --ff-only origin/main`, then answer the new questions: `chezmoi init` (interactive: `Does this machine have a desktop environment (not WSL)` → no; `Install system files under /etc (needs sudo)` → the user's choice: yes installs the `ssh_config.d` file, which affects only WSL's own ssh client). Then `chezmoi apply`.
- [ ] **Personal PopOS desktop:** install chezmoi from the pinned release (commands in `tests/clean-room.sh`), `chezmoi init --apply cyberflamingo/dotfiles` with `work=no`, `desktop=yes`, `system_files=yes`. Check `/etc/NetworkManager/conf.d/` and `/etc/ssh/ssh_config.d/default.conf`, run `mozilla-apply-overrides -n` to see which profiles it finds, then without `-n`, then the arkenfox `updater.sh` the user already uses.
- [ ] **Windows (work):** `winget install twpayne.chezmoi`, `chezmoi init --apply cyberflamingo/dotfiles` (answer `no` to the Linux-only questions if asked), check that `upall.cmd` is in `shell:startup`, run it once by hand and read `%LOCALAPPDATA%\\upall.log`. If winget is blocked by policy, tell the agent; do not work around it.
- [ ] **Router:** create the Proton Pass item (vault `Personal`, title `router-ups`, fields `upsname`, `hostname`, `username`, `password`), log in with `pass-cli login`, then `tools/deploy-router.sh --dry-run <ssh-host>`. The masked output shows the structure. If it fails with "unexpected pass-cli output shape", run `pass-cli item view --vault-name Personal --item-title router-ups --field upsname --output json` by hand, tell the agent what it prints, and `field()` gets adjusted. Then run it without `--dry-run`, and with `--restart` once the config is confirmed.
- [ ] **COSMIC (later):** `chezmoi add ~/.config/cosmic/<the files to keep>` on the desktop, review the diff for machine-specific values, commit.

---

## Self-review against the spec

| Spec item | Task |
|---|---|
| `system/` tree for files outside `$HOME`, installed by a script | 2 |
| Router deployed over SSH, not installed on the router | 3, 9 |
| Proton Pass first use | 3 |
| Windows `upall` winget-only, startup, no admin | 6 |
| dotbot, `meta/`, `install`, `bootstrap/`, submodules removed | 8 |
| dnscrypt and dnsmasq | dropped by decision (deleted in 8) |
| Parity of platforms through data flags | 1 |

Not here by design: privoxy redo, COSMIC capture, package lists and tiers (plan 2d), a CI job (blocked by the account billing lock).

## Known risks

- The JSON shape of `pass-cli ... --output json` for a single field is the one thing not verified from documentation; the script fails loudly and the user's first dry run settles it.
- `scp -O` assumes a Dropbear or OpenSSH router; if the router lacks a legacy scp server, set `SCP_OPTS=` empty to use SFTP.
- Windows behavior (Startup folder, winget policy, CRLF handling) can only be checked by the user.
- `chezmoi apply` fails with a missing-key error on any machine that has not re-run `chezmoi init` after Task 1 is merged.
