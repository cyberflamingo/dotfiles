##
## the_future2.kak by CyberFlamingo
##

evaluate-commands %sh{
    black_lighterer='rgb:383838'
    black_lighter='rgb:2D2D2D'
    black_light='rgb:1C1C1C'
    cyan_light='rgb:7CB0FF'
    green_dark='rgb:A1B56C'
    grey_dark='rgb:585858'
    grey_light='rgb:D8D8D8'
    magenta_dark='rgb:AB4642'
    magenta_light='rgb:AB4434'
    orange_dark='rgb:DC9656'
    orange_light='rgb:F7CA88'
    purple_dark='rgb:BA8BAF'

    red_light='rgb:FF5570'
    blue_light='rgb:6179DE'
    red_dark='rgb:D25061'
    yellow_light='rgb:FFE667'
    green_dark='rgb:76ABA5'
    green_light='rgb:48B9AC'
    purple_light='rgb:776CC9'
    black_dark='rgb:0F0910'

    ## Code
    echo "
        face global value      ${green_light}+b
        face global type       ${blue_light}+b
        face global identifier ${red_dark}
        face global string     ${red_light}
        face global error      default,white+b
        face global keyword    ${yellow_light}+b
        face global operator   ${cyan_light}
        face global attribute  ${orange_dark}
        face global comment    ${purple_light}

        face global variable   ${magenta_dark}
        face global module     ${green_dark}
        face global function   ${cyan_light}

        # #include <...>
        face global meta ${orange_light}
        face global builtin default+b
    "

    ## Markup
    echo "
        face global title  ${purple_light}+b
        face global header ${cyan_light}
        face global bold   ${orange_light}
        face global italic ${orange_dark}
        face global mono   ${green_dark}
        face global block  ${orange_dark}
        face global link   blue
        face global bullet ${magenta_light}
        face global list   ${magenta_dark}
    "

    # Builtin
    # fg,bg+attributes
    # face global Default default,rgb:262626 <- change the terminal bg color instead
    echo "
        face global Default            default,default

        face global PrimarySelection   white,${blue_light}
        face global SecondarySelection ${black_dark},${blue_light}

        face global PrimaryCursor      ${black_dark},white+fg
        face global SecondaryCursor    ${black_dark},white+fg

        face global PrimaryCursorEol   black,${cyan_light}+fg
        face global SecondaryCursorEol black,${cyan_light}+fg

        face global LineNumbers        ${purple_light}
        face global LineNumberCursor   ${grey_light},rgb:282828+b

        # Bottom menu:
        # text + background
        face global MenuBackground ${black_dark},${orange_light}
        # selected entry in the menu (use 302028 when true color support is fixed)
        face global MenuForeground white,${red_light}+b

        # completion menu info
        face global MenuInfo ${green_dark}

        # assistant, [+]
        face global Information ${black_dark},${yellow_light}

        face global Error      ${red_light},${black_dark}
        face global StatusLine ${green_light},default

        # Status line modes and prompts:
        # insert, prompt, enter key...
        face global StatusLineMode ${yellow_light}

        # 1 sel
        face global StatusLineInfo ${purple_light},${black_dark}

        # param=value, reg=value. ex: \"ey
        face global StatusLineValue ${green_light},${black_dark}

        face global StatusCursor ${black_dark},${yellow_light}

        # :
        face global Prompt ${black_dark},${yellow_light}

        # (), {}
        face global MatchingChar ${cyan_light},${black_light}+b

        # EOF tildas (~)
        face global BufferPadding ${red_light}

        # Whitespace characters
        face global Whitespace ${grey_dark}+f

        # Search
        face global Search default,rgb:333333+i
    "
}
