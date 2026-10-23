#!/usr/bin/env bash
# Check that bash, zsh and fish expose the same environment variables, PATH
# entries, aliases and commands. Starts real interactive login shells (inside a
# pty) against $HOME and only reads state.
#
# Usage: tests/shell-parity.sh [shell ...]    (default: bash zsh fish)
# Set PARITY_DEBUG=1 to print each shell's raw output to stderr.

set -u -o pipefail

VARS=(
    XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
    EDITOR VISUAL PAGER LESS LESSHISTFILE LESSOPEN LS_COLORS GCC_COLORS
    LESS_TERMCAP_md LESS_TERMCAP_us
    AWS_SHARED_CREDENTIALS_FILE AWS_CONFIG_FILE DOCKER_CONFIG
    CARGO_HOME GOPATH GOBIN JAVA_HOME _JAVA_OPTIONS MINIKUBE_HOME
    TERMINFO TERMINFO_DIRS NPM_CONFIG_USERCONFIG
    PSQLRC PSQL_HISTORY PGPASSFILE PGSERVICEFILE
    GEM_HOME GEM_SPEC_CACHE
    BUNDLE_USER_CONFIG BUNDLE_USER_CACHE BUNDLE_USER_PLUGIN
    VSCODE_PORTABLE WEGORC WINEPREFIX SSB_HOME BUN_INSTALL
)

# fish ships its own ll, la, l and grep, so those would pass without our
# config. Only names fish does not define are listed.
ALIASES=(copy move rmv da dir mpip rmcdir isodate)

# Commands every shell must find (functions count: zoxide defines z as one).
# Extra ones for a given machine: PARITY_EXTRA_COMMANDS='gws snyk' tests/shell-parity.sh
COMMANDS=(z mise starship fzf)
read -ra extra_commands <<<"${PARITY_EXTRA_COMMANDS:-}"
COMMANDS+=("${extra_commands[@]}")

PATH_DIRS=(
    "$HOME/.local/bin"
    "$HOME/.local/share/mise/shims"
    "$HOME/.local/share/cargo/bin"
    "$HOME/.local/share/go/bin"
    "$HOME/.local/share/gem/bin"
    "$HOME/.bun/bin"
)

# The snippets run inside the shell under test, so they must stay unexpanded.
# shellcheck disable=SC2016
BASH_SNIPPET='
for v in $PARITY_VARS; do printf "PARITY:var:%s=%s\n" "$v" "${!v-}"; done
for a in $PARITY_ALIASES; do alias "$a" >/dev/null 2>&1 && printf "PARITY:alias:%s\n" "$a"; done
for p in $PARITY_PATHS; do case ":$PATH:" in *":$p:"*) printf "PARITY:path:%s\n" "$p" ;; esac; done
for c in $PARITY_COMMANDS; do type -t "$c" >/dev/null 2>&1 && printf "PARITY:cmd:%s\n" "$c"; done'

# shellcheck disable=SC2016
ZSH_SNIPPET='
for v in ${=PARITY_VARS}; do print -r -- "PARITY:var:$v=${(P)v}"; done
for a in ${=PARITY_ALIASES}; do (( ${+aliases[$a]} + ${+functions[$a]} )) && print -r -- "PARITY:alias:$a"; done
for p in ${=PARITY_PATHS}; do [[ ":$PATH:" == *":$p:"* ]] && print -r -- "PARITY:path:$p"; done
for c in ${=PARITY_COMMANDS}; do (( ${+functions[$c]} + ${+commands[$c]} + ${+aliases[$c]} )) && print -r -- "PARITY:cmd:$c"; done'

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
end
for c in (string split " " -- $PARITY_COMMANDS)
    type -q $c; and printf "PARITY:cmd:%s\n" $c
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
    # shellcheck disable=SC2016
    cmd+=' PARITY_COMMANDS="$PARITY_COMMANDS"'
    cmd+=" $shell -ilc \"\$PARITY_SNIPPET\""
    raw=$(PARITY_VARS="${VARS[*]}" PARITY_ALIASES="${ALIASES[*]}" PARITY_PATHS="${existing[*]}" \
        PARITY_COMMANDS="${COMMANDS[*]}" \
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
