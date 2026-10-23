#!/usr/bin/env bash
# Test home/dot_local/bin/executable_mozilla-apply-overrides against fake profiles.
# The bash -c snippets are meant to stay unexpanded until they run.
# shellcheck disable=SC2016
set -u

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
helper=$repo/home/dot_local/bin/executable_mozilla-apply-overrides
home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
fail=0
check() {
    local desc=$1
    shift
    if "$@"; then
        echo "ok   $desc"
    else
        echo "FAIL $desc"
        fail=1
    fi
}

mkdir -p "$home/.config/mozilla-overrides"
echo "std" >"$home/.config/mozilla-overrides/firefox-user-overrides.js"
echo "dev" >"$home/.config/mozilla-overrides/firefox-user-overrides-dev.js"
echo "tb" >"$home/.config/mozilla-overrides/thunderbird-user.js"

# a deb-style Firefox with a default and a dev profile, a relative and an absolute path
mkdir -p "$home/.mozilla/firefox/abc.default-release" "$home/.mozilla/firefox/xyz.dev-edition" "$home/elsewhere"
cat >"$home/.mozilla/firefox/profiles.ini" <<EOT
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
EOT
# a Flatpak Thunderbird
mkdir -p "$home/.var/app/org.mozilla.Thunderbird/.thunderbird/tb.default"
cat >"$home/.var/app/org.mozilla.Thunderbird/.thunderbird/profiles.ini" <<EOT
[Profile0]
Name=default
IsRelative=1
Path=tb.default
EOT

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
