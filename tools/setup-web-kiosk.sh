#!/usr/bin/env bash

set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash tools/setup-web-kiosk.sh --url URL --compose-dir DIRECTORY [--service-name NAME]

Example:
  bash tools/setup-web-kiosk.sh \
    --url http://127.0.0.1:5000/ \
    --compose-dir "$HOME/Projects/toolbox/toolbox-backend" \
    --service-name toolbox
EOF
}

url=""
compose_dir=""
service_name="web-kiosk"

while (($#)); do
  case "$1" in
    --url)
      url=${2:?Missing value for --url}
      shift 2
      ;;
    --compose-dir)
      compose_dir=${2:?Missing value for --compose-dir}
      shift 2
      ;;
    --service-name)
      service_name=${2:?Missing value for --service-name}
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ $EUID -eq 0 ]]; then
  echo "Run this script as the desktop user, not as root." >&2
  exit 1
fi

if [[ -z $url || -z $compose_dir ]]; then
  usage >&2
  exit 1
fi

compose_dir=$(realpath "$compose_dir")
if [[ ! -f "$compose_dir/compose.yaml" &&
      ! -f "$compose_dir/compose.yml" &&
      ! -f "$compose_dir/docker-compose.yaml" &&
      ! -f "$compose_dir/docker-compose.yml" ]]; then
  echo "No Compose file found in: $compose_dir" >&2
  exit 1
fi

if ! [[ $service_name =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "Service name may contain only letters, numbers, underscores, and hyphens." >&2
  exit 1
fi

if ! command -v google-chrome-stable >/dev/null 2>&1; then
  if ! command -v yay >/dev/null 2>&1; then
    echo "Google Chrome is not installed and the yay AUR helper was not found." >&2
    echo "Install yay, review the google-chrome PKGBUILD, and rerun this script." >&2
    exit 1
  fi

  echo "Installing Google Chrome from the Arch User Repository..."
  yay -S --needed google-chrome
fi

if ! command -v curl >/dev/null 2>&1; then
  sudo pacman -S --needed curl
fi

service_file=$(mktemp)
trap 'rm -f "$service_file"' EXIT

cat >"$service_file" <<EOF
[Unit]
Description=$service_name Docker Compose application
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=$USER
SupplementaryGroups=docker
WorkingDirectory=$compose_dir
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose stop
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo install -m 0644 "$service_file" "/etc/systemd/system/$service_name.service"
sudo systemctl daemon-reload
sudo systemctl enable --now "$service_name.service"

mkdir -p "$HOME/.local/bin" "$HOME/.config/autostart"

launcher="$HOME/.local/bin/$service_name-kiosk"
cat >"$launcher" <<EOF
#!/usr/bin/env bash

url='$url'
profile_dir="\$HOME/.local/share/$service_name-kiosk-profile"

mkdir -p "\$profile_dir"
touch "\$profile_dir/First Run"

for ((attempt = 1; attempt <= 60; attempt++)); do
  if curl --fail --silent --show-error --max-time 2 "\$url" >/dev/null; then
    # Let the GNOME session finish restoring panels and windows before Chrome
    # requests focus. A dedicated profile prevents an existing normal Chrome
    # process from absorbing the kiosk launch flags.
    sleep 2
    exec /usr/bin/google-chrome-stable \
      --user-data-dir="\$profile_dir" \
      --kiosk \
      --start-fullscreen \
      --no-first-run \
      --no-default-browser-check \
      --disable-fre \
      --disable-session-crashed-bubble \
      --disable-infobars \
      "\$url"
  fi
  sleep 2
done

echo "Timed out waiting for \$url" >&2
exit 1
EOF
chmod 0755 "$launcher"

cat >"$HOME/.config/autostart/$service_name-kiosk.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$service_name kiosk
Comment=Open $url when the desktop session starts
Exec=$launcher
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

echo
echo "Kiosk setup complete."
echo "Compose service: $service_name.service"
echo "Kiosk URL:      $url"
echo "Autostart file: $HOME/.config/autostart/$service_name-kiosk.desktop"
echo
echo "Reboot to test the complete startup sequence."
echo "If GNOME shows a login screen, enable Automatic Login for this user first."
