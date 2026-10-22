# Check that the interactive zsh config bound and loaded what it should.
# Run it inside an interactive zsh (it needs the line editor and the plugins):
#   zsh -ilc 'source tests/zsh-smoke.zsh'
# It prints SMOKE-OK or SMOKE-FAIL and exits with 0 or 1.

typeset -A want
want=(
    '^I' fzf-tab-complete
    '^[[A' up-line-or-beginning-search
    '^[[B' down-line-or-beginning-search
    '\e\e' sudo-command-line
    '^[[1;3D' cd-back
    '^[[1;3C' cd-forward
    '^[[1;3A' cd-up
    '^[[1;3B' cd-down
    '^_' undo
    '^[/' redo
    '^F' jump_after_first_word
    '^Z' grml-zsh-fg
    '^H' backward-kill-subword
    '^R' fzf-history-widget
)

fail=0
for k in ${(k)want}; do
    got=$(bindkey "$k" 2>&1 | awk '{print $2}')
    if [[ $got != $want[$k] ]]; then
        print -u2 "FAIL bindkey $k: want $want[$k], got ${got:-nothing}"
        fail=1
    fi
done

for c in z mise starship fzf; do
    whence $c >/dev/null || { print -u2 "FAIL command not found: $c"; fail=1 }
done

(( $+functions[_zsh_highlight] )) || { print -u2 "FAIL syntax highlighting not loaded"; fail=1 }
(( $+functions[_zsh_autosuggest_start] )) || { print -u2 "FAIL autosuggestions not loaded"; fail=1 }
[[ $PROMPT == *starship* ]] || { print -u2 "FAIL prompt is not starship"; fail=1 }
[[ -o auto_cd && -o share_history && -o no_beep ]] || { print -u2 "FAIL expected options are not set"; fail=1 }

if (( fail )); then
    print SMOKE-FAIL
    exit 1
fi
print SMOKE-OK
exit 0
