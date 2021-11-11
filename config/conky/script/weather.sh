#!/usr/bin/env bash

set -euf pipefail

# Requires:
# * Geocode (GNOME)
# * wego (Go)
# * ansito (Python)

# Variables
# Config
export GEOCODE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"/geocode-glib
export CONKY_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"/conky
LAST_MODIFIED=$(ls -t "$GEOCODE_CACHE" | head -n1)
export LAST_MODIFIED
export WEGORC="${XDG_CONFIG_HOME:-$HOME/.config}"/wego/wegorc
# bin
export GOBIN="${XDG_DATA_HOME:-$HOME/.local/share}"/go/bin
export LOCALBIN=$HOME/.local/bin

# TODO check if Geocode exist, otherwise don't copy
# Could use geoclue where-am-i for backup
mkdir -p "$CONKY_CACHE"
cp "$GEOCODE_CACHE"/"$LAST_MODIFIED" "$CONKY_CACHE"/location.json

LAT=$(jq -r '.lat' "$CONKY_CACHE"/location.json)
export LAT
LON=$(jq -r '.lon' "$CONKY_CACHE"/location.json)
export LON

# Run wego
"$GOBIN"/wego "$LAT","$LON" | head -n 7 | "$LOCALBIN"/ansito -
