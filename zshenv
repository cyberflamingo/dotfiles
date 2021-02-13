## Custom configuration
umask 022

# XDG Base Directory
export XDG_DATA_HOME=$HOME/.local/share
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache

# Editor
export VISUAL='/usr/bin/kak'
export EDITOR='/usr/bin/kak'

# GO
export GOPATH=$XDG_DATA_HOME/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN

# Rust
export CARGO_HOME=$XDG_DATA_HOME/cargo
export PATH=$PATH:$CARGO_HOME/bin

