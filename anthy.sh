#!/usr/bin/env bash
# Install ibus-gtk
# see https://bugs.launchpad.net/ubuntu/+source/ibus-anthy/+bug/1854610
sudo apt install ibus-gtk and ibus-gtk3

# Not usefull now but could be in the future
# see https://unix.stackexchange.com/a/262220
#export GTK_IM_MODULE="ibus" >> ~/.xprofile
#export QT_IM_MODULE="ibus" >> ~/.xprofile
#export XMODIFIERS="@im=ibus" >> ~/.xprofile
