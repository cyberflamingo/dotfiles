#!/bin/bash

if test ! "$( which brew )"; then
    echo "Installing Homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    # Disable analytics
    brew analytics off
fi

brew update
brew upgrade

echo -e "\\n\\nInstalling Homebrew Cask applications..."
echo "========================================"

formulas=(
    apptrap
    atom
    brave
    #clementine # Doesn't work on non-admin account...
    cryptomator
    #dupeguru
    firefox
    imageoptim
    keepassxc
    keka
    #master-password # Cask is dead. PR if I have time
    #minecraft # This is a work computer
    standard-notes
    #steam # What did I told ya?
    torbrowser
    vlc
    wire
)

for formula in "${formulas[@]}"; do
    formula_name=$( echo "$formula" | awk '{print $1}' )
    if brew cask list "$formula_name" > /dev/null 2>&1; then
        echo "$formula_name already installed... skipping."
    else
        brew cask install "$formula"
    fi
done
