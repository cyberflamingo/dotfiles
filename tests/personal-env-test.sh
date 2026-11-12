#!/usr/bin/env bash
# Test the Proton Pass wiring: the personal.env template, the proton_pass prompt in
# .chezmoi.toml.tmpl, and the .profile hook. Uses a stub pass-cli, nothing leaves this machine.

# The bash -c snippets are meant to stay unexpanded until they run.
# shellcheck disable=SC2016
set -u

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/home/.config/shell"
: >"$work/empty.toml"
export STUB_LOG=$work/pass-cli.args
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

# stub pass-cli: logs its arguments, answers with a note that has blank lines around it
cat >"$work/bin/pass-cli" <<'EOF'
#!/bin/sh
printf '[%s]' "$@" >>"$STUB_LOG"
printf '\nFOO=bar\nBAZ="qux quux"\n\n'
EOF
chmod +x "$work/bin/pass-cli"

template=$repo/home/dot_config/private_shell/private_personal.env.tmpl
render() { # proton_pass value
    PATH="$work/bin:$PATH" chezmoi --config "$work/empty.toml" execute-template \
        --override-data "{\"proton_pass\": $1}" <"$template"
}

: >"$STUB_LOG"
out=$(render true)
check "note is rendered and trimmed" test "$out" = 'FOO=bar
BAZ="qux quux"'
check "item is read once, the URI (with its space) as one argument" test "$(cat "$STUB_LOG")" = '[item][view][pass://Secure Notes/dotfiles-personal-env/note]'

: >"$STUB_LOG"
out=$(render false)
check "disabled renders nothing" test -z "$out"
check "disabled never calls pass-cli" test ! -s "$STUB_LOG"

# the prompt strings are the --promptBool keys
p_work='Is this a work machine'
p_proton='Read personal secrets from Proton Pass (pass-cli, logged in)'
p_desktop='Does this machine have a desktop environment (not WSL)'
p_system='Install system files under /etc (needs sudo)'
config() { # work value, proton_pass answer
    chezmoi --config "$work/empty.toml" execute-template --init \
        --promptBool "$p_work=$1" --promptBool "$p_proton=$2" \
        --promptBool "$p_desktop=false" --promptBool "$p_system=false" \
        <"$repo/home/.chezmoi.toml.tmpl"
}
check "personal machine can turn it on" bash -c 'grep -q "proton_pass = true" <<<"$1"' _ "$(config false true)"
check "personal machine can leave it off" bash -c 'grep -q "proton_pass = false" <<<"$1"' _ "$(config false false)"
check "work machine is never asked, stays off" bash -c 'grep -q "proton_pass = false" <<<"$1"' _ "$(config true true)"

# .profile sources the rendered file when it is there, and does not mind when it is not
profile() {
    env -i HOME="$work/home" XDG_CONFIG_HOME="$work/home/.config" PATH=/usr/bin:/bin \
        bash -c '. "$1"; echo "${PERSONAL_ENV_TEST:-unset}"' _ "$repo/home/dot_profile" 2>/dev/null | tail -1
}
check "profile without personal.env leaves the variable unset" test "$(profile)" = unset
echo 'export PERSONAL_ENV_TEST=sourced' >"$work/home/.config/shell/personal.env"
check "profile sources personal.env" test "$(profile)" = sourced

exit "$fail"
