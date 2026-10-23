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
(`op`, or `op.exe` on WSL); a personal machine reads nothing. On Linux it also asks whether the
machine has a desktop (Mozilla overrides, NetworkManager files) and whether to install the files
under `system/` into `/etc` (uses sudo).

On Windows, install chezmoi with `winget install twpayne.chezmoi`, run
`chezmoi init --apply cyberflamingo/dotfiles` and answer `false` to the Linux questions. Only
`AppData` is applied there (a Startup script that runs `winget upgrade --all`).

| Path | What |
| --- | --- |
| `home/` | the chezmoi source, applied to `~` |
| `system/` | files for `/etc`, and the OpenWrt router config |
| `tools/` | scripts, e.g. `deploy-router.sh` (fills in the secrets from Proton Pass, then uploads) |
| `tests/` | shell parity, zsh smoke, clean-room and script tests |
| `extras/` | old files that are not applied (privoxy, to be redone) |

Edit the files in the source directory (`chezmoi cd`, then `home/`), and run `chezmoi apply`. If you
changed a file in `~` directly, `chezmoi re-add` copies it back.

Checks: `pre-commit run --all-files`, `tests/shell-parity.sh`, `tests/clean-room.sh`.

Pinned downloads (kakoune's `plug.kak`) are listed with commit and checksum in
`home/.chezmoiexternal.toml`. To update one: put the new commit in the URL, the new `sha256sum` of
the archive in `checksum.sha256`, then `chezmoi apply`.

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
