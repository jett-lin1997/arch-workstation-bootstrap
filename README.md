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
bash bootstrap.sh
```

Reboot once so the new Docker group membership applies:

```bash
sudo reboot
```

Then verify the installation:

```bash
cd arch-workstation-bootstrap
bash verify.sh
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

## Optional web kiosk

The optional kiosk tool starts a Docker Compose application during boot, waits
for its web page to respond, and opens Google Chrome in full-screen kiosk mode
after the desktop user logs in.

Google Chrome is installed from the Arch User Repository through `yay`. Review
the displayed PKGBUILD information before approving the installation.

Example for a local Compose application:

```bash
cd arch-workstation-bootstrap

bash tools/setup-web-kiosk.sh \
  --url http://127.0.0.1:5000/ \
  --compose-dir "$HOME/Projects/toolbox/toolbox-backend" \
  --service-name toolbox
```

Reboot to test the complete startup sequence:

```bash
sudo reboot
```

The browser starts after the GNOME user session begins. Enable GNOME Automatic
Login separately if the machine must reach the kiosk without user interaction.

The kiosk uses a dedicated Chrome profile and delays its launch for two seconds so the
first-run welcome page and GNOME focus timing do not prevent full-screen mode.
