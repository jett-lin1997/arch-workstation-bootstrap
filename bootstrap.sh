#!/usr/bin/env bash

set -Eeuo pipefail

readonly PACKAGES=(
  docker
  docker-buildx
  docker-compose
  curl
  fish
  git
  htop
  ncdu
  nmap
  nodejs
  npm
  openssh
  python
  ranger
  smartmontools
  sshfs
  vim
)

if [[ $EUID -eq 0 ]]; then
  echo "Run this script as a regular user, not as root." >&2
  exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
  echo "This bootstrap supports Arch Linux and Arch-based distributions only." >&2
  exit 1
fi

echo "Installing workstation packages..."
sudo pacman -Syu --needed "${PACKAGES[@]}"

echo "Enabling system services..."
sudo systemctl enable --now docker.service
sudo systemctl enable --now sshd.service
sudo systemctl enable --now smartd.service

if ! id -nG "$USER" | grep -qw docker; then
  echo "Adding $USER to the docker group..."
  sudo usermod -aG docker "$USER"
fi

fish_path=$(command -v fish)
current_shell=$(getent passwd "$USER" | cut -d: -f7)
if [[ $current_shell != "$fish_path" ]]; then
  echo "Setting Fish as the default shell for $USER..."
  sudo chsh -s "$fish_path" "$USER"
fi

echo
echo "Bootstrap complete. Reboot once to activate Docker group membership and Fish:"
echo "  sudo reboot"
