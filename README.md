# Arch Workstation Bootstrap

An idempotent bootstrap for Arch Linux and Arch-based workstations, including
EndeavourOS laptops, desktops, and mini PCs.

## Included tools

- Containers: Docker, Docker Buildx, Docker Compose
- Development: Git, Vim, Python, Node.js, npm
- Shell and terminal: Fish, htop, ncdu, Ranger
- Network and remote access: OpenSSH, SSHFS, Nmap
- Storage monitoring: smartmontools

## Usage

Clone the repository and run the bootstrap as a regular user:

```bash
git clone https://github.com/jett-lin1997/arch-workstation-bootstrap.git
cd arch-workstation-bootstrap
./bootstrap.sh
```

Reboot once so the new Docker group membership applies:

```bash
sudo reboot
```

Then verify the installation:

```bash
cd arch-workstation-bootstrap
./verify.sh
```

## Notes

- The script uses `pacman --needed`, so it can be run repeatedly without
  reinstalling packages that are already present.
- It enables Docker, OpenSSH server, and SMART monitoring at boot.
- Fish is installed but is not made the default shell. This avoids surprising
  compatibility issues with existing Bash-based administration scripts.
- Review your firewall and SSH authentication policy before exposing SSH to an
  untrusted network.
- Do not commit passwords, access tokens, private SSH keys, `.env` files, or
  organization-specific configuration to this repository.

## Supported systems

- Arch Linux
- EndeavourOS
- Other Arch-based distributions using `pacman` and systemd
