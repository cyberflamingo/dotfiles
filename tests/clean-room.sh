#!/usr/bin/env bash
# Apply the dotfiles in a clean Ubuntu container, install the prompt tools with
# mise, and run the parity test and the zsh smoke test there. This is the
# closest thing to a fresh machine.
#
# Usage: tests/clean-room.sh [image]    (default: ubuntu:24.04)

set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
image=${1:-ubuntu:24.04}
chezmoi_version=2.73.3
chezmoi_sha256=6e5827598cbfc02d132b04f95b5ea10efb5b79230e2a4a0e52df4af144a8ee9f
mise_version=2026.10.17
mise_sha256=17565e268c5542d8ce944321e17af81e0b741b65af4aa7e8e010ee77376a4aa3

docker run --rm -i -v "$repo":/src:ro "$image" bash -s -- \
    "$chezmoi_version" "$chezmoi_sha256" "$mise_version" "$mise_sha256" <<'EOF'
set -euo pipefail
chezmoi_version=$1
chezmoi_sha256=$2
mise_version=$3
mise_sha256=$4

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends ca-certificates curl git fish zsh less >/dev/null

cd /tmp
curl -fsSL -o chezmoi.tar.gz "https://github.com/twpayne/chezmoi/releases/download/v${chezmoi_version}/chezmoi_${chezmoi_version}_linux_amd64.tar.gz"
echo "${chezmoi_sha256}  chezmoi.tar.gz" | sha256sum --check
tar -xzf chezmoi.tar.gz chezmoi
install -m 0755 chezmoi /usr/local/bin/chezmoi

curl -fsSL -o mise.tar.gz "https://github.com/jdx/mise/releases/download/v${mise_version}/mise-v${mise_version}-linux-x64.tar.gz"
echo "${mise_sha256}  mise.tar.gz" | sha256sum --check
tar -xzf mise.tar.gz mise/bin/mise

useradd --create-home --shell /bin/bash tester
install -d -o tester -g tester /home/tester/.local /home/tester/.local/bin
install -m 0755 -o tester -g tester mise/bin/mise /home/tester/.local/bin/mise
cp -a /src /home/tester/dotfiles
chown -R tester:tester /home/tester/dotfiles

cat >/home/tester/run.sh <<'INNER'
set -euo pipefail
cd ~/dotfiles
chezmoi init --source ~/dotfiles --promptDefaults --apply --exclude=scripts
echo "--- applied files:"; chezmoi managed | wc -l
~/.local/bin/mise install starship zoxide fzf 2>&1 | tail -2
echo "--- parity (bash, zsh, fish):"
~/dotfiles/tests/shell-parity.sh
echo "--- zsh smoke test:"
out=$(script -qec "env -i HOME=$HOME USER=$USER TERM=xterm-256color LANG=C.UTF-8 PATH=/usr/bin:/bin zsh -ilc 'source $HOME/dotfiles/tests/zsh-smoke.zsh'" /dev/null </dev/null | tr -d '\r')
printf '%s\n' "$out" | tail -8
printf '%s\n' "$out" | grep -q SMOKE-OK
INNER
chown tester:tester /home/tester/run.sh
su - tester -c 'bash /home/tester/run.sh'
EOF
