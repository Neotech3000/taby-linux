#!/usr/bin/env sh
set -eu

PLUGIN_ID="enochlawrence.yutaro-assistant"
PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins"
TARGET="$PLUGINS_DIR/$PLUGIN_ID"
MARKER="$TARGET/.yutaro-linux-local-install"
SOURCE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ -L "$TARGET" ] || [ ! -d "$TARGET" ] || [ ! -f "$MARKER" ]; then
  printf 'Not removing an unmanaged plugin path: %s\n' "$TARGET" >&2
  exit 1
fi
INSTALLED_FROM=$(cat "$MARKER")
if [ "$INSTALLED_FROM" != "$SOURCE" ]; then
  printf 'Refusing to remove a copy installed from another source: %s\n' "$INSTALLED_FROM" >&2
  exit 1
fi

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin disable "$PLUGIN_ID"
fi
rm -r -- "$TARGET"
printf 'Removed the managed plugin copy at %s\n' "$TARGET"
