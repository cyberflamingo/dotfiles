#!/usr/bin/env bash

# TODO:
# * Add error check
# * Better handle repositories for udpade
# * Use gsettings.sh first

###############################################################################
# Appearance Settings                                                         #
###############################################################################

echo 'Applying appearance settings...'

###############################################################################
# Variables                                                                   #
###############################################################################

REPOSITORY_DIR=$HOME/Development/src/github.com/vinceliuice
THEME_APP_DIR=$REPOSITORY_DIR/Matcha-gtk-theme
THEME_CUR_DIR=$REPOSITORY_DIR/Qogir-icon-theme

###############################################################################
# Dependencies                                                                #
###############################################################################

sudo apt-get update
sudo apt-get -y install gtk2-engines-murrine gtk2-engines-pixbuf

###############################################################################
# Themes: Applications                                                        #
###############################################################################

git clone https://github.com/vinceliuice/Matcha-gtk-theme.git "$THEME_APP_DIR"

bash "$THEME_APP_DIR"/install.sh --color dark --theme aliz

gsettings set org.gnome.desktop.interface gtk-theme 'Matcha-dark-aliz'

flatpak install -y flathub org.gtk.Gtk3theme.Matcha-dark-azul

###############################################################################
# Themes: Cursor                                                              #
###############################################################################

git clone https://github.com/vinceliuice/Qogir-icon-theme.git "$THEME_CUR_DIR"

bash "$THEME_CUR_DIR"/install.sh

gsettings set org.gnome.desktop.interface cursor-theme 'Qogir-ubuntu'

###############################################################################
# Themes: Icons                                                               #
###############################################################################

gsettings set org.gnome.desktop.interface icon-theme 'Qogir-ubuntu'

###############################################################################
# Themes: Shell                                                               #
###############################################################################

gsettings set org.gnome.shell.extensions.user-theme name 'Pop-dark'
gsettings set org.gnome.shell.extensions.user-theme name 'Matcha-dark-aliz'

###############################################################################
# Themes: Gnome Terminal                                                      #
###############################################################################

# Save with this command (replacing the string with whatever it is you have):
# dconf dump /org/gnome/terminal/legacy/profiles:/:49cc915e-fb7c-4bfb-be99-f4839b4c63d2/ > gnome-terminal.dconf.bak
dconf load /org/gnome/terminal/legacy/profiles:/:49cc915e-fb7c-4bfb-be99-f4839b4c63d2/ <gnome-terminal.dconf

echo 'Every tasks done.'
