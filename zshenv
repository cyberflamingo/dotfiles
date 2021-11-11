umask 022

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
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

# zsh
export ZDOTDIR=$XDG_CONFIG_HOME/zsh

# Aspell
export ASPELL_CONF="per-conf $XDG_CONFIG_HOME/aspell/aspell.conf; \
                    personal $XDG_CONFIG_HOME/aspell/en.pws;      \
                    repl $XDG_CONFIG_HOME/aspell/en.prepl"

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
# Maven
# mvn -gs "$XDG_CONFIG_HOME"/maven/settings.xml

# LESS
export LESSHISTFILE=-

# npm
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc

# Ruby
export GEM_HOME=$XDG_DATA_HOME/gem
export PATH="$PATH:$GEM_HOME/bin"
export GEM_SPEC_CACHE=$XDG_CACHE_HOME/gem
# rbenv
export RBENV_ROOT=$XDG_DATA_HOME/rbenv
# Bundler
export BUNDLE_USER_CONFIG=$XDG_CONFIG_HOME/bundle
export BUNDLE_USER_CACHE=$XDG_CACHE_HOME/bundle
export BUNDLE_USER_PLUGIN=$XDG_DATA_HOME/bundle

# VSCodium
# Note: not documented, might break
export VSCODE_PORTABLE=$XDG_DATA_HOME/vscode

# Wego
export WEGORC=$XDG_CONFIG_HOME/wego/wegorc

# Zoom
export SSB_HOME=$XDG_DATA_HOME/zoom
