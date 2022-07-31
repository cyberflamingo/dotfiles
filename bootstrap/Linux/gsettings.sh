#!/usr/bin/env bash

# TODO:
# * Add error check
# * Add dash-to-dock settings
# * Make sure apps, extensions and fonts are installed first

# Setting dconf profile with information from this page
# https://askubuntu.com/a/967535
# https://askubuntu.com/a/971190

###############################################################################
# Variables                                                                   #
###############################################################################

GSETTINGS=gsettings

###############################################################################
# Backup current settings                                                     #
###############################################################################

dconf dump / >dconf.bak
gsettings list-recursively >gsettings.bak

###############################################################################
# Recursively set gsettings                                                   #
###############################################################################

while read -r schema key value; do
    [[ "$schema" =~ ^#.*$ ]] || [ -z "$schema" ] && continue
    gsettings set "$schema" "$key" "$value"
    # echo "$schema" "$key" "$(gsettings get "$schema" "$key")"
done <"$GSETTINGS"
