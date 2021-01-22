#!/bin/bash

echo "Now may be a good time to connect to Internet"

# Install Xcode
echo
echo "We are going to install Xcode"
xcode-select --install

###############################################################################
# Homebrew and Cask                                                           #
###############################################################################

echo
echo "Next step we are going to install Homebrew and Homebrew-Cask"
echo "along with commonly used applications and/or services."
echo

# Install Homebrew and several packages
bash brew.sh

# Install several apps through Homebrew-Cask
bash brew-cask.sh
# Also need to add HOMEBREW_NO_INSECURE_REDIRECT=1 and HOMEBREW_CASK_OPTS=--require-sha to shell or shell rc file (export ... command)

###############################################################################
# Hosts                                                                       #
###############################################################################

echo
echo "We are going to update the hosts files with some quality unified hosts"
echo

echo "Installing dependencies."
echo "Auto replace hosts with 0.0.0.0 and extensions fakenews, gambling, porn"

if test ! "$( which python3 )"; then
  pip3 install --user -r requirements.txt
  python3 updateHostsFile.py --auto --replace --ip 0.0.0.0 --extensions fakenews gambling porn
else
  pip2 install --user -r requirements_python2.txt
  python updateHostsFile.py --auto --replace --ip 0.0.0.0 --extensions fakenews gambling porn
fi

###############################################################################
# DNScrypt                                                                    #
###############################################################################

echo
echo "DNScrypt!"
echo "Backup current config file and copy new config file to the right location."

# Update homebrew.mxcl.dnscrypt-proxy.plist (use the one in config file)
# See the sample configuration file for dnscrypt-proxy to block domains ans shit

echo
echo "(Re)start the service! Yeay!"
sudo brew services restart dnscrypt-proxy

###############################################################################
# dnsmasq and DNSSEC                                                          #
###############################################################################

echo
echo "dnsmasq!"
echo "Backup current config file and copy new config file to the right location."
# Use dnsmasq.conf in config

echo
echo "Start the service! Yeay!"
sudo brew services start dnsmasq

echo
echo "Set dnsmasq as local DNS for Wi-Fi and Ethernet."
sudo networksetup -setdnsservers "Wi-fi" 127.0.0.1
sudo networksetup -setdnsservers "Ethernet" 127.0.0.1

# Couldn't make dnscrypt-proxy and dnsmasq work together. Gonna dive into that later

###############################################################################
# OpenSSL and Curl                                                            #
###############################################################################

# Those settings should be in my bash or zsh.
# There is nothing to do here.

# Need to export it to Bash because Apple deprecated Openssl (not nice, Apple)
#echo 'export PATH="/usr/local/opt/openssl/bin:$PATH"' >> ~/.bash_profile
#echo 'export PATH="/usr/local/opt/curl/bin:$PATH"' >> ~/.bash_profile

# May be good to add some option to ~/.curlrc as well

###############################################################################
# Privoxy                                                                     #
###############################################################################

# Install and launch Privoxy
echo
echo "Launch Privoxy!"
brew services start privoxy

echo
echo "Set the HTTP and HTTPS proxy."
echo "Note: software can choose to bypass system's configuration."
echo "Make sure to configure each software's proxy if necessary."
sudo networksetup -setwebproxy "Wi-Fi" 127.0.0.1 8118
sudo networksetup -setwebproxy "Ethernet" 127.0.0.1 8118
sudo networksetup -setsecurewebproxy "Wi-Fi" 127.0.0.1 8118
sudo networksetup -setsecurewebproxy "Ethernet" 127.0.0.1 8118

echo
echo "Backup current config file and copy new config file to the right location."
# May be good to add some rule to /usr/local/etc/privoxy/user.action as well

###############################################################################
# GnuPG                                                                       #
###############################################################################

# Those settings should be in my bash or zsh.
# There is nothing to do here.

# Tweak /.gnupg/gpg.conf for some more security

###############################################################################
# Profanity                                                                   #
###############################################################################

# Install Profanity (when I have time to learn how to use it)
#brew install profanity

###############################################################################
# Tor Browser                                                                 #
###############################################################################

# Copy the config file in the right folder.
# Configure Tor and obfuscate or use a bridge

###############################################################################
# santa                                                                       #
###############################################################################

# Installing santa from Google seems like a cool security feature as well

###############################################################################
# Go                                                                          #
###############################################################################

# Those settings should be in my bash or zsh.
# There is nothing to do here.
# After doing the brew command:
# Settings for go
export PATH=$PATH:/usr/local/opt/go/libexec/bin
# And other $GOPATH, $GOBIN...
# https://golang.org/doc/code.html#GOPATH

echo
echo "Aaaaand we are done with apps!"
echo "Next section is opinionated UI settings."
echo "Those settings should be run in the day-to-day user account."
echo
echo "bash macos_4settings.sh"
