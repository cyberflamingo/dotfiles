# the_future2 theme for Kakoune
# https://github.com/cyberflamingo
#
# Inspired by Dracula theme for Kakoune
# https://draculatheme.com/kakoune

# Color palette
declare-option str black             'rgb:0F0910'
declare-option str purple_dark       'rgb:2D1A30'
declare-option str red               'rgb:FF5570'
declare-option str cyan              'rgb:7CB0FF'
declare-option str green             'rgb:48B9AC'
declare-option str yellow            'rgb:FFE667'
declare-option str blue              'rgb:6179DE'
declare-option str orange            'rgb:DC9656'
declare-option str orange_light      'rgb:F7CA88'
declare-option str purple            'rgb:776CC9'
declare-option str white             default

declare-option str background        "%opt{black}"
declare-option str dimmed_background "%opt{purple_dark}"
declare-option str foreground        "%opt{white}"

# Reference
# https://github.com/mawww/kakoune/blob/master/colors/default.kak
# For code
set-face global value      "%opt{green}+b"
set-face global type       "%opt{blue}+b"
set-face global variable   "%opt{red}"
set-face global module     "%opt{green}"
set-face global function   "%opt{cyan}"
set-face global string     "%opt{red}"
set-face global keyword    "%opt{yellow}+b"
set-face global operator   "%opt{orange}"
set-face global attribute  "%opt{orange_light}"
set-face global comment    "%opt{purple}+i"
# #include <...>
set-face global meta       "%opt{orange_light}"
set-face global builtin    "%opt{white}+b"
# set-face global identifier "%opt{red}"

# For markup
set-face global title  "%opt{red}+b"
set-face global header "%opt{orange}+b"
set-face global bold   "%opt{orange_light}+b"
set-face global italic "%opt{orange_light}+i"
set-face global mono   "%opt{green}"
set-face global block  "%opt{cyan}"
set-face global link   "%opt{cyan}+i"
set-face global bullet "%opt{green}"
set-face global list   "%opt{red}"

# Builtin faces
set-face global Default            "%opt{foreground}"
set-face global PrimarySelection   "%opt{black},%opt{orange_light}"
set-face global SecondarySelection "%opt{black},%opt{purple}"
set-face global PrimaryCursor      "%opt{black},%opt{cyan}"
set-face global SecondaryCursor    "%opt{black},%opt{orange}"
set-face global PrimaryCursorEol   "%opt{black},%opt{cyan}"
set-face global SecondaryCursorEol "%opt{black},%opt{orange}"
set-face global LineNumbers        "%opt{purple}"
set-face global LineNumberCursor   "%opt{white},%opt{purple}+b"
set-face global LineNumbersWrapped "%opt{dimmed_background}+i"
# Bottom menu:
# selected entry in the menu
set-face global MenuForeground     "%opt{white},%opt{red}+b"
# text + background
set-face global MenuBackground     "%opt{black},%opt{orange_light}"
# completion menu info
set-face global MenuInfo           "%opt{purple_dark}+i"
# assistant, [+]
set-face global Information        "%opt{purple_dark},%opt{yellow}"
set-face global Error              "%opt{black},%opt{red}"
set-face global StatusLine         "%opt{white},%opt{background}"
# Status line modes and prompts:
# insert, prompt, enter key...
set-face global StatusLineMode     "%opt{black},%opt{green}"
# 1 sel
set-face global StatusLineInfo     "%opt{purple},%opt{background}"
# param=value, reg=value. ex: \"ey
set-face global StatusLineValue    "%opt{orange}"
set-face global StatusCursor       "%opt{white},%opt{blue}"
# :
set-face global Prompt             "%opt{black},%opt{yellow}"
# (), {}
set-face global MatchingChar       "%opt{black},%opt{blue}"
# Whitespace characters
set-face global Whitespace         "%opt{purple}+f"
set-face global WrapMarker         Whitespace
# EOF tildas (~)
set-face global BufferPadding      "%opt{red}"
# Search
# set-face global Search             Prompt
