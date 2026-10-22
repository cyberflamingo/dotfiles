```
   ▗                                                        ▖▖
 ▝▖ ▌      ▌      ▌▌        ▗  ▄▄   ▚▞▀    ▝▚▖    ▄     ▗ ▗▄▙▘
▝▄▙▀▛▘    ▞    ▝▖▝▖          ▀▀ ▐  ▝▄▄▀▜     ▝▘    ▘ ▐   ▀▘ ▐
  ▌ ▌   ▄▀▖    ▐  ▐  ▝▘  ▝▘     ▌      ▞   ▝▀▄       ▌      ▞
  ▘▐      ▌   ▗▘   ▌           ▞      ▗▘   ▄▖       ▞     ▗▄▌
  ▗▘      ▌   ▘    ▘         ▗▞     ▗▞▘     ▝▚▖  ▝▄▀     ▀▘ ▘
```

# dotfiles

My _in progress_ dotfiles for my everyday activities.

Mainly a bunch of files and scripts and a hope to automate all of it someday.

## Install

Managed with [chezmoi](https://www.chezmoi.io/). On a new Linux or WSL machine, install chezmoi
from a pinned, checksum-verified release (the exact commands are in `tests/clean-room.sh`), then:

```sh
chezmoi init --apply cyberflamingo/dotfiles
```

`chezmoi init` asks once whether this is a work machine. Work values are read from 1Password
(`op`, or `op.exe` on WSL); a personal machine reads nothing.

Edit the files in the source directory (`chezmoi cd`, then `home/`), and run `chezmoi apply`. If you
changed a file in `~` directly, `chezmoi re-add` copies it back.

Checks: `pre-commit run --all-files`, `tests/shell-parity.sh`, `tests/clean-room.sh`.

## TODO

A lot.

### Software configs to add

* fzf

### Script to... script

* Automate the installation of this repository
* Update macOS dotfiles
* Add Windows dotfiles

## Fonts

Fonts I like to use for programming.

* Meslo Nerd Font patched for Powerlevel10k
* IBM Plex Mono

## Wallpaper

https://josan.artstation.com/

## Thanks to this people

... for the inspiration in making my dotfiles.

https://github.com/drduh/config

https://github.com/mathiasbynens/dotfiles

https://github.com/myfreeweb/dotfiles

https://github.com/apas/dotfiles
