#!/usr/bin/env bash
# Apply the dotfiles in a clean Ubuntu container and run the parity test there.
# This is the closest thing to a fresh machine. zsh is skipped: z4h downloads
# itself on first start, which a clean-room test should not do.
#
# Usage: tests/clean-room.sh [image]    (default: ubuntu:24.04)

set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
image=${1:-ubuntu:24.04}
chezmoi_version=2.73.3
chezmoi_sha256=6e5827598cbfc02d132b04f95b5ea10efb5b79230e2a4a0e52df4af144a8ee9f

docker run --rm -i -v "$repo":/src:ro "$image" bash -s -- "$chezmoi_version" "$chezmoi_sha256" <<'EOF'
set -euo pipefail
version=$1
sha256=$2

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends ca-certificates curl git fish less >/dev/null

cd /tmp
curl -fsSL -o chezmoi.tar.gz "https://github.com/twpayne/chezmoi/releases/download/v${version}/chezmoi_${version}_linux_amd64.tar.gz"
echo "${sha256}  chezmoi.tar.gz" | sha256sum --check
tar -xzf chezmoi.tar.gz chezmoi
install -m 0755 chezmoi /usr/local/bin/chezmoi

useradd --create-home --shell /bin/bash tester
cp -a /src /home/tester/dotfiles
chown -R tester:tester /home/tester/dotfiles

su - tester -c '
    set -euo pipefail
    cd ~/dotfiles
    chezmoi init --source ~/dotfiles --promptDefaults --apply --exclude=scripts
    echo "--- applied files:"; chezmoi managed | wc -l
    echo "--- parity (bash, fish):"
    ~/dotfiles/tests/shell-parity.sh bash fish
'
EOF
