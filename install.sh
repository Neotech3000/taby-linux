#!/usr/bin/env sh
set -eu
APP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APPLICATIONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$APPLICATIONS_DIR"
cat > "$APPLICATIONS_DIR/taby-linux.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Taby for Linux
Comment=Local-first desktop companion
Exec=$APP_DIR/run.sh
Icon=$APP_DIR/taby.svg
Terminal=false
Categories=Utility;
StartupWMClass=taby-linux
EOF
chmod 644 "$APPLICATIONS_DIR/taby-linux.desktop"
printf 'Installed launcher: %s\n' "$APPLICATIONS_DIR/taby-linux.desktop"
