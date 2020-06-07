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

THEME_APP_DIR=$HOME/Matcha-gtk-theme
THEME_CUR_DIR=$HOME/Qogir-icon-theme
ICO_DEST_DIR="/usr/share/icons"


###############################################################################
# Dependencies                                                                #
###############################################################################

sudo add-apt-repository ppa:papirus/papirus
sudo apt-get update
sudo apt-get -y install gtk2-engines-murrine gtk2-engines-pixbuf \
  papirus-icon-theme papirus-folders libreoffice-style-papirus


###############################################################################
# Themes: Applications                                                        #
###############################################################################

git clone https://github.com/vinceliuice/Matcha-gtk-theme.git "$THEME_APP_DIR"

sudo bash "$THEME_APP_DIR"/install.sh --color dark --theme aliz

gsettings set org.gnome.desktop.interface gtk-theme 'Matcha-dark-aliz'

flatpak install -y flathub org.gtk.Gtk3theme.Matcha-dark-azul

rm -rf "$THEME_APP_DIR"


###############################################################################
# Themes: Cursor                                                              #
###############################################################################

git clone https://github.com/vinceliuice/Qogir-icon-theme.git "$THEME_CUR_DIR"

sudo cp -r "$THEME_CUR_DIR"/src/cursors/dist-ubuntu/ \
  $ICO_DEST_DIR/Qogir-ubuntu-cursors

gsettings set org.gnome.desktop.interface cursor-theme 'Qogir-ubuntu-cursors'

rm -rf "$THEME_CUR_DIR"


###############################################################################
# Themes: Icons                                                               #
###############################################################################

gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'

papirus-folders -C red --theme Papirus-Dark


###############################################################################
# Themes: Shell                                                               #
###############################################################################

gsettings set org.gnome.shell.extensions.user-theme name Pop-dark
gsettings set org.gnome.shell.extensions.user-theme name 'Matcha-dark-aliz'


###############################################################################
# Themes: Gnome Terminal                                                      #
###############################################################################

# Save with this command (replacing the string with whatever it is you have):
# dconf dump /org/gnome/terminal/legacy/profiles:/:49cc915e-fb7c-4bfb-be99-f4839b4c63d2/ > gnome-terminal.dconf
dconf load /org/gnome/terminal/legacy/profiles:/:49cc915e-fb7c-4bfb-be99-f4839b4c63d2/ < gnome-terminal.dconf

echo 'Every tasks done.'
