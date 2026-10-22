# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
if [[ $EUID -eq 0 ]]; then
    umask 027
else
    umask 027
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        # shellcheck source=/dev/null
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

## Custom configuration

# XDG Base Directory
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache

# Editor
if command -v kak 1>/dev/null 2>&1; then
    kak="$(which kak)"
    export VISUAL=$kak
    export EDITOR=$kak
else
    vi="$(which vi)"
    export VISUAL=$vi
    export EDITOR=$vi
fi

# Aspell
export ASPELL_CONF="per-conf $XDG_CONFIG_HOME/aspell/aspell.conf; \
                    personal $XDG_CONFIG_HOME/aspell/en.pws;      \
                    repl $XDG_CONFIG_HOME/aspell/en.prepl"

# AWS
export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME"/aws/credentials
export AWS_CONFIG_FILE="$XDG_CONFIG_HOME"/aws/config

# Cargo
export CARGO_HOME=$XDG_DATA_HOME/cargo
export PATH="$PATH:$CARGO_HOME/bin"

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker

# GnuPG
# export GNUPGHOME=$XDG_DATA_HOME/gnupg
if [ -n "$ZSH_VERSION" ]; then
    export GPG_TTY=$TTY
else
    tty=$(tty)
    export GPG_TTY=$tty
fi

# GO
export GOPATH=$XDG_DATA_HOME/go
export GOBIN=$GOPATH/bin
export PATH="$PATH:$GOBIN"

# Java
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java
export JAVA_HOME=/usr/lib/jvm/default-java
export PATH="$PATH:$JAVA_HOME/bin"
# Maven
# mvn -gs "$XDG_CONFIG_HOME"/maven/settings.xml

# LESS
export LESSHISTFILE=-
# printf instead of $'...', which is not POSIX
LESS_TERMCAP_mb=$(printf '\033[1;31m')  # begin blink
LESS_TERMCAP_md=$(printf '\033[1;36m')  # begin bold
LESS_TERMCAP_me=$(printf '\033[0m')     # reset bold/blink
LESS_TERMCAP_so=$(printf '\033[01;33m') # begin reverse video
LESS_TERMCAP_se=$(printf '\033[0m')     # reset reverse video
LESS_TERMCAP_us=$(printf '\033[1;32m')  # begin underline
LESS_TERMCAP_ue=$(printf '\033[0m')     # reset underline
export LESS_TERMCAP_mb LESS_TERMCAP_md LESS_TERMCAP_me LESS_TERMCAP_so LESS_TERMCAP_se LESS_TERMCAP_us LESS_TERMCAP_ue

# Pager
PAGER=$(command -v less)
export PAGER

# minikube
export MINIKUBE_HOME="$XDG_DATA_HOME"/minikube

# ncurses
export TERMINFO="$XDG_DATA_HOME"/terminfo
export TERMINFO_DIRS="$XDG_DATA_HOME"/terminfo:/usr/share/terminfo

# npm
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc

# PostgreSQL
export PSQLRC=$XDG_CONFIG_HOME/pg/psqlrc
export PSQL_HISTORY=$XDG_STATE_HOME/psql_history
export PGPASSFILE=$XDG_CONFIG_HOME/pg/pgpass
export PGSERVICEFILE=$XDG_CONFIG_HOME/pg/pg_service.conf

# Ruby
export GEM_HOME=$XDG_DATA_HOME/gem
export PATH="$PATH:$GEM_HOME/bin"
export GEM_SPEC_CACHE=$XDG_CACHE_HOME/gem
# rbenv
export RBENV_ROOT=$XDG_DATA_HOME/rbenv
export PATH="$PATH:$RBENV_ROOT/bin"
# Bundler
export BUNDLE_USER_CONFIG=$XDG_CONFIG_HOME/bundle
export BUNDLE_USER_CACHE=$XDG_CACHE_HOME/bundle
export BUNDLE_USER_PLUGIN=$XDG_DATA_HOME/bundle

# VSCodium
# Note: not documented, might break
export VSCODE_PORTABLE=$XDG_DATA_HOME/vscode

# Wego
export WEGORC=$XDG_CONFIG_HOME/wego/wegorc

# Wine
export WINEPREFIX="$XDG_DATA_HOME"/wineprefixes/default

# z.lua
export _ZL_DATA=$XDG_DATA_HOME/zlua

# Zoom
export SSB_HOME=$XDG_DATA_HOME/zoom

# asdf
export ASDF_DATA_DIR="$XDG_CONFIG_HOME/asdf"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

[ -r "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# WSL needs DISPLAY for X apps
if grep -qi microsoft /proc/version 2>/dev/null; then
    export DISPLAY=:0
fi

# Machine-local values (work tokens, endpoints, WSL helpers). Not tracked in git.
if [ -r "$XDG_CONFIG_HOME/shell/work.env" ]; then
    # shellcheck source=/dev/null
    . "$XDG_CONFIG_HOME/shell/work.env"
fi
