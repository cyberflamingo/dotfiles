if status is-login
    if test "$EUID" = 0
        umask 027
    else
        umask 027
    end

    # set fish_add_path --prepend so it includes user's private bin if it exists
    if test -d "$HOME/.local/bin"
        fish_add_path $HOME/.local/bin
    end


    ## Custom configuration

    # XDG Base Directory
    set -x XDG_DATA_HOME $HOME/.local/share
    set -x XDG_STATE_HOME $HOME/.local/state
    set -x XDG_CONFIG_HOME $HOME/.config
    set -x XDG_CACHE_HOME $HOME/.cache

    # Tmux
    if test -n "$TMUX"
        set -x TERM tmux
    end

    # Editor
    if command -v kak 1>/dev/null 2>&1
        set -u kak (which kak)
        set -x VISUAL $kak
        set -x EDITOR $kak
    else
        set -u vi (which vi)
        set -x VISUAL $vi
        set -x EDITOR $vi
    end

    # Pager
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

    # Aspell
    set -x ASPELL_CONF "per-conf $XDG_CONFIG_HOME/aspell/aspell.conf; \
                        personal $XDG_CONFIG_HOME/aspell/en.pws;      \
                        repl $XDG_CONFIG_HOME/aspell/en.prepl"

    # AWS
    set -x AWS_SHARED_CREDENTIALS_FILE "$XDG_CONFIG_HOME"/aws/credentials
    set -x AWS_CONFIG_FILE "$XDG_CONFIG_HOME"/aws/config

    # Cargo
    set -x CARGO_HOME $XDG_DATA_HOME/cargo
    fish_add_path --append "$CARGO_HOME/bin"

    # Docker
    set -x DOCKER_CONFIG "$XDG_CONFIG_HOME"/docker

    # GnuPG
    # set -x GNUPGHOME $XDG_DATA_HOME/gnupg
    set -u tty (tty)
    set -x GPG_TTY $tty

    # GO
    set -x GOPATH $XDG_DATA_HOME/go
    set -x GOBIN $GOPATH/bin
    fish_add_path --append "$GOBIN"

    # Java
    set -x _JAVA_OPTIONS -Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java
    set -x JAVA_HOME /usr/lib/jvm/default-java
    fish_add_path --append "$JAVA_HOME/bin"
    # Maven
    # mvn -gs "$XDG_CONFIG_HOME"/maven/settings.xml

    # LESS
    set -x LESSHISTFILE -
    # what zsh4humans used to set: case-insensitive search, raw colors, quit if one screen
    set -x LESS '-iRFXMx4'

    # minikube
    set -x MINIKUBE_HOME "$XDG_DATA_HOME"/minikube

    # ncurses
    set -x TERMINFO "$XDG_DATA_HOME"/terminfo
    set -x TERMINFO_DIRS "$XDG_DATA_HOME"/terminfo:/usr/share/terminfo

    # npm
    set -x NPM_CONFIG_USERCONFIG $XDG_CONFIG_HOME/npm/npmrc

    # PostgreSQL
    set -x PSQLRC $XDG_CONFIG_HOME/pg/psqlrc
    set -x PSQL_HISTORY $XDG_STATE_HOME/psql_history
    set -x PGPASSFILE $XDG_CONFIG_HOME/pg/pgpass
    set -x PGSERVICEFILE $XDG_CONFIG_HOME/pg/pg_service.conf

    # Ruby
    set -x GEM_HOME $XDG_DATA_HOME/gem
    fish_add_path --append "$GEM_HOME/bin"
    set -x GEM_SPEC_CACHE $XDG_CACHE_HOME/gem
    # rbenv
    set -x RBENV_ROOT $XDG_DATA_HOME/rbenv
    fish_add_path --append "$RBENV_ROOT/bin"
    # Bundler
    set -x BUNDLE_USER_CONFIG $XDG_CONFIG_HOME/bundle
    set -x BUNDLE_USER_CACHE $XDG_CACHE_HOME/bundle
    set -x BUNDLE_USER_PLUGIN $XDG_DATA_HOME/bundle

    # VSCodium
    # Note: not documented, might break
    set -x VSCODE_PORTABLE $XDG_DATA_HOME/vscode

    # Wego
    set -x WEGORC $XDG_CONFIG_HOME/wego/wegorc

    # Wine
    set -x WINEPREFIX "$XDG_DATA_HOME"/wineprefixes/default

    # Bun
    set -x BUN_INSTALL "$HOME/.bun"
    fish_add_path --append "$BUN_INSTALL/bin"

    # Zoom
    set -x SSB_HOME $XDG_DATA_HOME/zoom

    # mise: shims for non-interactive use, and the real bin directories of the installed
    # tools in front of them (see ~/.profile for why there is no `mise activate`)
    fish_add_path --prepend "$XDG_DATA_HOME/mise/shims"
    if test -x "$HOME/.local/bin/mise"
        set -l mise_cache "$XDG_CACHE_HOME/mise-bin-paths"
        if not test -s "$mise_cache"; or test "$XDG_CONFIG_HOME/mise/config.toml" -nt "$mise_cache"; or test "$XDG_DATA_HOME/mise/installs" -nt "$mise_cache"
            mkdir -p "$XDG_CACHE_HOME"
            env -C "$HOME" "$HOME/.local/bin/mise" bin-paths 2>/dev/null | paste -sd: >"$mise_cache.tmp"; and mv -f "$mise_cache.tmp" "$mise_cache"
        end
        set -l mise_path
        read -l mise_path <"$mise_cache" 2>/dev/null
        test -n "$mise_path"; and set -gx PATH (string split : -- $mise_path) $PATH
    end
end

# Commands to run in interactive sessions can go here
if status is-interactive
    ## Imported from bashrc

    # make less more friendly for non-text input files, see lesspipe(1)
    test -x /usr/bin/lesspipe && eval (SHELL=/bin/sh lesspipe)

    # enable color support of ls and also add handy aliases
    # (the aliases themselves now live in ~/.aliases)
    if test -x /usr/bin/dircolors
        test -r ~/.dircolors && eval (dircolors -c ~/.dircolors) || eval (dircolors -c)
    end

    # Alias definitions.
    # You may want to put all your additions into a separate file like
    # ~/.aliases, instead of adding them here directly.
    # See /usr/share/doc/bash-doc/examples in the bash-doc package.

    if test -f ~/.aliases
        . ~/.aliases
    end

    # fish has no $OLDPWD, so rmcdir overrides the shared alias
    function rmcdir --description 'Remove the current (empty) directory and go up'
        set -l dir $PWD
        cd ..; and rmdir $dir; or cd $dir
    end

    # colored GCC warnings and errors
    set -x GCC_COLORS 'error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'


    ## Custom configuration

    # Nix
    # if [ -e "$HOME"/.nix-profile/etc/profile.d/nix.sh ]; then . "$HOME"/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
    # fisher install lilyball/nix-env.fish

    # Ruby
    if test -x "$RBENV_ROOT/bin/rbenv" # not `command -v`: it walks the slow /mnt/c PATH entries on WSL
        "$RBENV_ROOT/bin/rbenv" init - fish | source
    end

    # Python
    if command -v pipx 1>/dev/null 2>&1
        if not test -f ~/.config/fish/completions/pipx.fish
            register-python-argcomplete --shell fish pipx >~/.config/fish/completions/pipx.fish
        end
    end

    # the tools mise installs (their directories are put on PATH by the login block above)
    command -q fzf; and fzf --fish | source
    command -q zoxide; and zoxide init fish | source

    # Keybindings vi or default (emac?)
    # fish_vi_key_bindings
    # fish_default_key_bindings

    if command -v starship 1>/dev/null 2>&1
        starship init fish --print-full-init | source
    end
end

# Executed when login shell exits.
function on_exit --on-event fish_exit

    # when leaving the console clear the screen to increase privacy

    if test "$SHLVL" = 1
        test -x /usr/bin/clear_console && /usr/bin/clear_console -q
    end
end
