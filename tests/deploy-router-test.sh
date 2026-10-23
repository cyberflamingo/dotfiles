#!/usr/bin/env bash
# Test tools/deploy-router.sh with stub pass-cli, ssh and scp. Nothing leaves this machine.

# The bash -c snippets are meant to stay unexpanded until they run.
# shellcheck disable=SC2016
set -u

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/log"
export STUB_LOG=$work/log
fail=0

check() { # description, command...
    local desc=$1
    shift
    if "$@"; then
        echo "ok   $desc"
    else
        echo "FAIL $desc"
        fail=1
    fi
}

# stub pass-cli: one field comes back in the object shape, the others as strings
cat >"$work/bin/pass-cli" <<'EOF'
#!/bin/sh
case "$*" in
    *"--field upsname"*) echo '"my ups"' ;;
    *"--field hostname"*) echo '{"value": "192.0.2.10"}' ;;
    *"--field username"*) echo '"monuser"' ;;
    *"--field password"*) printf '"%s"\n' "${STUB_PASSWORD:-s3cret-Pw}" ;;
    *)
        echo "unexpected: $*" >&2
        exit 1
        ;;
esac
EOF
# stub scp keeps a copy of what would be uploaded; stub ssh logs its command line
cat >"$work/bin/scp" <<'EOF'
#!/bin/sh
echo "$*" >"$STUB_LOG/scp.args"
src=
for a in "$@"; do
    case $a in
        -*) ;;
        *:*) ;;
        *) src=$a ;;
    esac
done
cp "$src" "$STUB_LOG/uploaded"
stat -c %a "$src" >"$STUB_LOG/uploaded.mode"
EOF
cat >"$work/bin/ssh" <<'EOF'
#!/bin/sh
echo "$*" >>"$STUB_LOG/ssh.args"
EOF
chmod +x "$work/bin/"*

run() { PATH="$work/bin:$PATH" PASS_CLI="$work/bin/pass-cli" "$repo/tools/deploy-router.sh" "$@"; }

# 1. dry run: exits 0, shows no secret, uploads nothing
out=$(run --dry-run router 2>&1)
check "dry run succeeds" test $? -eq 0
check "dry run output contains no secret" bash -c '! printf "%s" "$1" | grep -qE "s3cret-Pw|monuser|192.0.2.10|my ups"' _ "$out"
check "dry run masks the four options" bash -c '[ "$(printf "%s\n" "$1" | grep -c "<filled>")" -eq 4 ]' _ "$out"
check "dry run does not upload" test ! -e "$work/log/scp.args"

# 2. real run: uploads a filled, private file and installs it with a backup
run --restart router >/dev/null 2>&1
check "real run succeeds" test $? -eq 0
check "scp used the legacy protocol and the router" grep -q -- '-O -q .* router:/tmp/nut_monitor.new' "$work/log/scp.args"
check "uploaded file has the values" bash -c 'grep -q "option password .s3cret-Pw." "$1" && grep -q "option hostname .192.0.2.10." "$1" && grep -q "option upsname .my ups." "$1" && grep -q "option username .monuser." "$1"' _ "$work/log/uploaded"
check "uploaded file has no placeholder left" bash -c '! grep -qE "\$(UPSNAME|UPS_)" "$1"' _ "$work/log/uploaded"
check "uploaded file was private (600)" grep -qx 600 "$work/log/uploaded.mode"
check "ssh installs with chmod 600 and a backup" grep -q 'chmod 600 /tmp/nut_monitor.new.*nut_monitor.bak.*mv /tmp/nut_monitor.new /etc/config/nut_monitor' "$work/log/ssh.args"
check "restart ran" grep -q '/etc/init.d/nut-monitor restart' "$work/log/ssh.args"

# 3. SCP_OPTS can be emptied (SFTP)
rm -f "$work/log/scp.args"
SCP_OPTS='' run router >/dev/null 2>&1
check "empty SCP_OPTS drops -O" bash -c '! grep -q -- "-O" "$1"' _ "$work/log/scp.args"

# 4. refuses a value UCI cannot hold
rm -f "$work/log/scp.args"
STUB_PASSWORD="it's" run router >/dev/null 2>&1
check "a password with a single quote is rejected" test $? -ne 0
check "nothing uploaded after the rejection" test ! -e "$work/log/scp.args"

# 5. usage errors
run >/dev/null 2>&1
check "no host is a usage error" test $? -eq 2
run --bogus router >/dev/null 2>&1
check "unknown option is a usage error" test $? -eq 2

exit $fail
