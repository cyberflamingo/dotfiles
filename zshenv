## Custom configuration
umask 022

# XDG Base Directory
export XDG_DATA_HOME=$HOME/.local/share
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache

# Editor
export VISUAL='/usr/bin/kak'
export EDITOR='/usr/bin/kak'

# zsh
export ZDOTDIR=$XDG_CONFIG_HOME/zsh

# Cargo
export CARGO_HOME=$XDG_DATA_HOME/cargo
export PATH="$PATH:$CARGO_HOME/bin"

# GnuPG
export GNUPGHOME=$XDG_DATA_HOME/gnupg

# GO
export GOPATH=$XDG_DATA_HOME/go
export GOBIN=$GOPATH/bin
export PATH="$PATH:$GOBIN"

# Java
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java
export JAVA_HOME=/usr/lib/jvm/default-java
export PATH="$PATH:$JAVA_HOME/bin"
# Gradle
# export GRADLE_USER_HOME=$XDG_DATA_HOME/gradle
# Maven
# mvn -gs "$XDG_CONFIG_HOME"/maven/settings.xml

# LESS
export LESSHISTFILE=-

# npm
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc

# Ruby
export GEM_HOME=$XDG_DATA_HOME/gem
export GEM_SPEC_CACHE=$XDG_CACHE_HOME/gem
# rbenv
export RBENV_ROOT=$XDG_DATA_HOME/rbenv

# VSCodium
# Note: not documented, might break
export VSCODE_PORTABLE=$XDG_DATA_HOME/vscode

# Wego
export WEGORC=$XDG_CONFIG_HOME/wego/wegorc

# Zoom
export SSB_HOME=$XDG_DATA_HOME/zoom
