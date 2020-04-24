#!/bin/bash

#set -o errtrace
#set -o nounset
#set -o pipefail

###############################################################################
# FireVault hardening                                                         #
###############################################################################

if fdesetup status | grep -q 'Off'; then
  echo "Wait. FireVault if OFF. You need to activate it first."
  echo
  bash macos_1firevault.sh
fi

echo
echo "Hey! It's you again!"
echo "Let's add several rules for security"
echo
echo "Destroy FireVault key on standby!"
echo

# Destroy FV key on standby
sudo pmset -a destroyfvkeyonstandby 1

echo "Set hibernation mode to 3..."

# Hibernation mode
sudo pmset -a hibernatemode 3

echo "Set power nap settings..."

# Power nap settings
sudo pmset -a powernap 0
sudo pmset -a standby 0
sudo pmset -a standbydelay 0
sudo pmset -a autopoweroff 0

###############################################################################
# Firewall settings                                                           #
###############################################################################

echo
echo "Let's configure the Firewall"
echo
echo "Enable Firewall globally..."

# Enable firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

echo "Set FW loggin on..."

# Enable logging
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setloggingmode on

echo "And also stealth mode..."

# Enable stealth mode
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

echo "Disable all whitelisting of software"

# Disable built-in software and code-signed, downloaded software from being whitelisted automatically
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned off
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsignedapp off

echo "And finally restart the firewall! BOOM"

# Restart firewall
sudo pkill -HUP socketfilterfw

echo "A more advanced user could use the Kernel level packet filtering."
echo "Take a look at 'pfctl' if that interest you."

###############################################################################
# Logs, artifacts and metadata                                                #
###############################################################################

echo
echo "Delete and disable the quarantine logs of download..."
# Disable Quarantine logs of download
:>~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2
sudo chflags schg ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2

echo
echo "Delete Bluetooth metadata."
echo "Note: there shouldn't be any if this is a clean install."

# It is possible to delete Bluetooth metadata in /Library/Preferences/com.apple.Bluetooth.plist
sudo defaults delete /Library/Preferences/com.apple.Bluetooth.plist DeviceCache
sudo defaults delete /Library/Preferences/com.apple.Bluetooth.plist IDSPairedDevices
sudo defaults delete /Library/Preferences/com.apple.Bluetooth.plist PANDevices
sudo defaults delete /Library/Preferences/com.apple.Bluetooth.plist PANInterfaces
sudo defaults delete /Library/Preferences/com.apple.Bluetooth.plist SCOAudioDevices

echo
echo "Delete CUPS printer job in cache."
echo "Note: there shouldn't be any if this is a clean install."

# And Also CUPS printer job cache in /var/spool/cups
sudo rm -rfv /var/spool/cups/c0*
sudo rm -rfv /var/spool/cups/tmp/*
sudo rm -rfv /var/spool/cups/cache/job.cache*

echo
echo "Deleting Wi-Fi data and start fresh, just in case."
echo "Indeed, Wi-Fi password aren't always deleted even after a clean install"
sudo nvram -d 36C28AB5-6566-4C50-9EBD-CBB920F83843:current-network
sudo nvram -d 36C28AB5-6566-4C50-9EBD-CBB920F83843:preferred-networks
sudo nvram -d 36C28AB5-6566-4C50-9EBD-CBB920F83843:preferred-count

echo
echo "Apple collect typestroks. Not on my watch!"
echo "Let's delete it then block further writting"
sudo rm -rfv "~/Library/LanguageModeling/*" "~/Library/Spelling/*" "~/Library/Suggestions/*"
sudo chmod -R 000 ~/Library/LanguageModeling ~/Library/Spelling ~/Library/Suggestions
sudo chflags -R uchg ~/Library/LanguageModeling ~/Library/Spelling ~/Library/Suggestions

echo
echo "Also let's delete and disable QuickLook metadata"
sudo rm -rfv ~/Library/Application\ Support/Quick\ Look/*
sudo chmod -R 000 ~/Library/Application\ Support/Quick\ Look/
sudo chflags -R uchg ~/Library/Application\ Support/Quick\ Look/

echo
echo "And finally, Siri Analytics Database, which we won't use I guess"
rm -rfv ~/Library/Assistant/SiriAnalytics.db
# Well you con't chmod a file that doesn't exist...
#sudo chmod -R 000 ~/Library/Assistant/SiriAnalytics.db
#sudo chflags -R uchg ~/Library/Assistant/SiriAnalytics.db

###############################################################################
# Other security/privacy related settings                                     #
###############################################################################

echo
echo "Next steps are some (opinionated) security settings"

echo
echo "Lock as soon as screensaver starts..."
echo "Note: doesn't work on High Sierra as of last time I checked..."
echo "Gotta do it in manually in System Preferences."
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

echo
echo "Show hidden files."
defaults write com.apple.finder AppleShowAllFiles -bool true
chflags nohidden ~/Library

echo
echo "Show all files extentions."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo
echo "Nuke iCloud default saving."
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

echo
echo "Disable crash reporters"
defaults write com.apple.CrashReporter DialogType none

echo
echo "Disable Bonjour"
sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool YES

echo "Enable Secure Keyboard Entry in Terminal"
defaults write com.apple.terminal SecureKeyboardEntry -bool true

echo "Desactive Captive Portal (may complicate things with Free Wifi)"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false

###############################################################################
# karek314/macOS-home-call-drop                                               #
###############################################################################

echo
echo "Important!"
echo "For the next step, you need to boot into Recovery Mode and bypass SIP"
echo "with the following command:"
echo
echo "csrutil disable"
echo
# echo "Git clone karek314/macOS-home-call-drop if not present."
echo "Then, modify karek314/macOS-home-call-drop to your liking and run it."
echo
echo "Last, don't forget to enable SIP again!"
echo
echo "csrutil enable"
echo
