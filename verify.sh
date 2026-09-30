#!/usr/bin/env bash

set -u

readonly COMMANDS=(
  docker
  fish
  git
  htop
  ncdu
  nmap
  node
  npm
  python
  ranger
  smartctl
  ssh
  sshfs
  vim
)

readonly SERVICES=(docker sshd smartd)
failed=0

echo "Commands"
for command_name in "${COMMANDS[@]}"; do
  if command_path=$(command -v "$command_name" 2>/dev/null); then
    printf "  %-12s OK  %s\n" "$command_name" "$command_path"
  else
    printf "  %-12s MISSING\n" "$command_name"
    failed=1
  fi
done

echo
echo "Services"
for service_name in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$service_name.service"; then
    printf "  %-12s active\n" "$service_name"
  else
    printf "  %-12s inactive or failed\n" "$service_name"
    failed=1
  fi
done

echo
if docker info >/dev/null 2>&1; then
  echo "Docker access: OK"
else
  echo "Docker access: FAILED (reboot or check docker group membership)"
  failed=1
fi

exit "$failed"

