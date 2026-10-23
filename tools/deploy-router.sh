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
scp_opts=${SCP_OPTS--O}

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

# shellcheck disable=SC2016
envsubst '$UPSNAME $UPS_HOSTNAME $UPS_USERNAME $UPS_PASSWORD' <"$template" >"$tmp/nut_monitor"

# shellcheck disable=SC2016
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
# shellcheck disable=SC2029
ssh "$host" "chmod 600 $remote_tmp && { [ -f /etc/config/nut_monitor ] && cp -a /etc/config/nut_monitor /etc/config/nut_monitor.bak || true; } && mv $remote_tmp /etc/config/nut_monitor"
echo "uploaded to $host:/etc/config/nut_monitor (previous copy kept as nut_monitor.bak)"
if [ "$restart" -eq 1 ]; then
    ssh "$host" '/etc/init.d/nut-monitor restart'
fi
