#!/usr/bin/env bash

if test ! "$( which apm )"; then
    echo "Atom and/or apm ain't installed, bro"
    break
fi

apm update
apm upgrade

###############################################################################
# Install packages                                                            #
###############################################################################

echo -e "\\n\\nInstalling Atom packages..."
echo "=============================="

formulas=(
    #color-picker
    file-icons
    firewatch-hot-syntax
    #firewatch-syntax
    japanese-wrap
    language-generic-config
    project-manager
    split-diff
)

for formula in "${formulas[@]}"; do
    apm install "$formula"
done


###############################################################################
# Disable packages                                                            #
###############################################################################

echo -e "\\n\\nDisabling Atom packages..."
echo "=============================="

disFormulas=(
    atom-dark-syntax
    atom-dark-ui
    atom-light-syntax
    atom-light-ui
    base16-tomorrow-dark-theme
    base16-tomorrow-light-theme
    one-light-ui
    one-dark-syntax
    one-light-syntax
    solarized-dark-syntax
    solarized-light-syntax
    about
    archive-view
    autocomplete-atom-api
    autocomplete-plus
    autocomplete-snippets
    background-tips
    bookmarks
    deprecation-cop
    dev-live-reload
    exception-reporting
    grammar-selector
    markdown-preview
    metrics
    open-on-github
    package-generator
    spell-check
    styleguide
    welcome
    language-c
    language-clojure
    language-csharp
    language-gfm
    language-java
    language-objective-c
    language-perl
    language-php
)

for disFormula in "${disFormulas[@]}"; do
    apm disable "$disFormula"
done
