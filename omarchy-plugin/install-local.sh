#!/usr/bin/env sh
set -eu

SOURCE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/enochlawrence.rose-assistant"
mkdir -p "$(dirname "$TARGET")"

if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  printf 'Refusing to replace existing path: %s\n' "$TARGET" >&2
  exit 1
fi

ln -s "$SOURCE" "$TARGET"
if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin validate "$TARGET"
fi
printf 'Installed local plugin source at %s\n' "$TARGET"
printf 'To enable after reviewing: omarchy plugin enable enochlawrence.rose-assistant right\n'
