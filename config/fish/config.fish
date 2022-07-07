if status is-login
    if test "$EUID" = 0
        umask 002
    else
        umask 022
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
        set -u KAK "(which kak)"
        set -x VISUAL $KAK
        set -x EDITOR $KAK
    else
        set -u VI "(which vi)"
        set -x VISUAL $VI
        set -x EDITOR $VI
    end

    # Pager
    set -u LESS "(which less)"
    set -x PAGER $LESS

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
    set -x GPG_TTY $TTY

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

    # minikube
    set -x MINIKUBE_HOME "$XDG_DATA_HOME"/minikube

    # ncurses
    set -x TERMINFO "$XDG_DATA_HOME"/terminfo
    set -x TERMINFO_DIRS "$XDG_DATA_HOME"/terminfo:/usr/share/terminfo

    # npm
    set -x NPM_CONFIG_USERCONFIG $XDG_CONFIG_HOME/npm/npmrc

    # nvm
    # Handled by jorgebucaran/nvm.fish plugin

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

    # Zoom
    set -x SSB_HOME $XDG_DATA_HOME/zoom
end

# Commands to run in interactive sessions can go here
if status is-interactive
    ## Imported from bashrc

    # make less more friendly for non-text input files, see lesspipe(1)
    test -x /usr/bin/lesspipe && eval (SHELL=/bin/sh lesspipe)

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

    # Alias definitions.
    # You may want to put all your additions into a separate file like
    # ~/.aliases, instead of adding them here directly.
    # See /usr/share/doc/bash-doc/examples in the bash-doc package.

    if test -f ~/.aliases
        . ~/.aliases
    end

    # colored GCC warnings and errors
    set -x GCC_COLORS 'error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'


    ## Custom configuration

    # Nix
    # if [ -e "$HOME"/.nix-profile/etc/profile.d/nix.sh ]; then . "$HOME"/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
    # fisher install lilyball/nix-env.fish

    # Ruby
    if command -v rbenv 1>/dev/null 2>&1
        rbenv init - fish | source
    end

    # Python
    if command -v pipx 1>/dev/null 2>&1
        if not test -f ~/.config/fish/completions/pipx.fish
            register-python-argcomplete --shell fish pipx >~/.config/fish/completions/pipx.fish
        end
    end

    # Keybindings vi or default (emac?)
    # fish_vi_key_bindings
    # fish_default_key_bindings

    starship init fish | source
end

# Executed when login shell exits.
function on_exit --on-event fish_exit

    # when leaving the console clear the screen to increase privacy

    if test "$SHLVL" = 1
        test -x /usr/bin/clear_console && /usr/bin/clear_console -q
    end
end
