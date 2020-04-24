#!/bin/bash

if test ! "$( which brew )"; then
    echo "Installing Homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    # Disable analytics
    brew analytics off
fi

brew update
brew upgrade

echo -e "\\n\\nInstalling Homebrew packages..."
echo "==============================="

formulas=(
    #caddy
    'curl --with-openssl'
    dnscrypt-proxy
    'dnsmasq --with-dnssec'
    git
    git-flow-avh
    gnupg
    go
    #hugo
    kakoune
    neovim
    openssl
    #openvpn
    privoxy
    #profanity
    python3
    #ruby
    rsync
    tmux
    #zsh
)

for formula in "${formulas[@]}"; do
    formula_name=$( echo "$formula" | awk '{print $1}' )
    if brew list "$formula_name" > /dev/null 2>&1; then
        echo "$formula_name already installed... skipping."
    else
        brew install "$formula"
    fi
done
