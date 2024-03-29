#!/usr/bin/env bash

cd "$HOME/.dotfiles/bootstrap/macOS" || exit
CUR_DIR=$(pwd)

command_exists() {
    type "$1" >/dev/null 2>&1
}

echo "Installing dotfiles."

echo "Initializing submodule(s)"
git submodule update --init --recursive

# shellcheck source=/dev/null
source "$CUR_DIR"/git.sh

# only perform macOS-specific install
if [ "$(uname)" == "Darwin" ]; then
    echo -e "\\n\\nRunning on OSX"

    # shellcheck source=/dev/null
    source "$CUR_DIR"/brew.sh
    # shellcheck source=/dev/null
    source "$CUR_DIR"/osx.sh
fi

# echo "creating vim directories"
# mkdir -p ~/.vim-tmp

if ! command_exists zsh; then
    echo "zsh not found. Please install and then re-run installation scripts"
    exit 1
elif ! [[ $SHELL =~ .*zsh.* ]]; then
    echo "Configuring zsh as default shell"
    chsh -s "$(which zsh)"
fi

echo "Done. Reload your terminal."
