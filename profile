# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
if [[ $EUID -eq 0 ]]; then
    umask 002
else
    umask 022
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
    KAK="$(which kak)"
    export VISUAL=$KAK
    export EDITOR=$KAK
else
    VI="$(which vi)"
    export VISUAL=$VI
    export EDITOR=$VI
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
export GPG_TTY=$TTY

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

# minikube
export MINIKUBE_HOME="$XDG_DATA_HOME"/minikube

# npm
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc

# nvm
export NVM_DIR="$XDG_DATA_HOME"/nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

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

# Zoom
export SSB_HOME=$XDG_DATA_HOME/zoom
