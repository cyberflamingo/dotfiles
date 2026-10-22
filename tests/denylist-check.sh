#!/usr/bin/env bash
# Fail if a file contains a term from the local, untracked denylist
# (~/.config/shell/denylist.txt, one term per line). Prints file:line only,
# never the matching text. Skips silently when the denylist does not exist
# (CI, other machines).
#
# Usage: tests/denylist-check.sh file...    (pre-commit passes the files)

set -u

list="${DENYLIST:-$HOME/.config/shell/denylist.txt}"
[ -r "$list" ] || exit 0

hits=$(grep -nIHiFf "$list" -- "$@" | cut -d: -f1,2)
if [ -n "$hits" ]; then
    printf '%s\n' "$hits"
    echo "denylisted term found (file:line above)" >&2
    exit 1
fi
