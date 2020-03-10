#!/bin/bash

#set -o errtrace
#set -o nounset
#set -o pipefail

echo "Hi."
echo "Welcome to your Mac OS setup!"
echo "I'm your guide. This gonna be goooood!"
echo
echo "First, let's see if FireVault is on..."
echo "If it's not, let's write some random"
echo "for better entropy."
echo

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if fdesetup status | grep -q 'Off'; then
  echo "FireVault if OFF."
  echo
  echo "Okay, let's invoke random!"
  echo "Type random characters for several minutes then press Ctrl + D"
  echo
  # Random seed for encryption disk
  cat > /dev/random

  echo
  echo "Enabling FireVault..."
  echo
  # Enable FireVault
  sudo fdesetup enable

  echo
  echo "We probably need to reboot now..."
  echo "After that, launch the next script for security!"
  echo
  sudo reboot
else
  echo "FireVault if ON."
  echo
  echo "Good. Let's check the security."
  # Launch Another Script
  bash macos_2security.sh
fi
