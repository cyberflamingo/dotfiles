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
sudo apt-get install gtk2-engines-murrine gtk2-engines-pixbuf \
  papirus-icon-theme


###############################################################################
# Themes: Applications                                                        #
###############################################################################

git clone https://github.com/vinceliuice/Matcha-gtk-theme.git "$THEME_APP_DIR"

sudo bash "$THEME_APP_DIR"/install.sh --color dark --theme aliz

gsettings set org.gnome.desktop.interface gtk-theme 'Matcha-dark-aliz'

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

# Returns "No such schema “org.gnome.shell.extensions.user-theme”"
# Therefore needs to be activated manually like a savage.
#gsettings set org.gnome.shell.extensions.user-theme name 'Matcha-dark-aliz'
echo 'Shell theme needs to be activated manually, like a savage.'

echo 'Every tasks done.'
