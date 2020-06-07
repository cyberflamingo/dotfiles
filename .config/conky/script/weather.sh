#!/usr/bin/env bash

# Requires:
# * Geocode (GNOME)
# * wego (Go)
# * ansito (Python)

# Variables
export GEOCODE_CACHE=$HOME/.cache/geocode-glib
export CONKY_CACHE=$HOME/.cache/conky
LAST_MODIFIED=$(ls -t "$GEOCODE_CACHE" | head -n1)
export LAST_MODIFIED
export GOBIN=$HOME/go/bin

# TODO check if Geocode exist, otherwise don't copy
# Could use geoclue where-am-i for backup
mkdir -p "$CONKY_CACHE"
cp "$GEOCODE_CACHE"/"$LAST_MODIFIED" "$CONKY_CACHE"/location.json

LAT=$(jq -r '.lat' "$CONKY_CACHE"/location.json)
export LAT
LON=$(jq -r '.lon' "$CONKY_CACHE"/location.json)
export LON


"$GOBIN"/wego "$LAT","$LON" | head -n 7 | ansito -
