#!/usr/bin/env bash

# First let's install ZSH
sudo apt-get install zsh

# Make zsh default shell
chsh -s "$(which zsh)"

# Install recommended font for Powerlevel10k
# TODO: Check if ~/.fonts exist before mkdir-ing it
FONTS=$HOME"/.fonts"
FONTS_REPO="https://github.com/romkatv/powerlevel10k-media/raw/master"

mkdir "$FONTS"
wget "$FONTS_REPO"/MesloLGS%20NF%20Regular.ttf -P "$FONTS"
wget "$FONTS_REPO"/MesloLGS%20NF%20Bold.ttf -P "$FONTS"
wget "$FONTS_REPO"/MesloLGS%20NF%20Italic.ttf -P "$FONTS"
wget "$FONTS_REPO"/MesloLGS%20NF%20Bold%20Italic.ttf -P "$FONTS"

# Update font cache
fc-cache -f -v

# Add font to terminal
gconftool-2 --set /apps/gnome-terminal/profiles/Default/font --type string "MesloLGS NF Regular"

exec "$SHELL"
