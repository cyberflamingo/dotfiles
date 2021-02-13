# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi


## Custom configuration

# XDG Base Directory
export XDG_DATA_HOME=$HOME/.local/share
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache

# Editor
export VISUAL='/usr/bin/kak'
export EDITOR='/usr/bin/kak'

# Bash
export HISTFILE="$XDG_DATA_HOME"/bash/history

# Cargo
export CARGO_HOME=$XDG_DATA_HOME/cargo
export PATH=$PATH:$CARGO_HOME/bin

# GnuPG
export GNUPGHOME="$XDG_DATA_HOME"/gnupg

# GO
export GOPATH=$XDG_DATA_HOME/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN

# LESS
export LESSHISTFILE=-

