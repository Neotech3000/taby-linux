#!/usr/bin/env sh
set -eu

SOURCE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/enochlawrence.rose-assistant"

if [ ! -L "$TARGET" ]; then
  printf 'Not removing a non-symlink or unrelated plugin path: %s\n' "$TARGET"
  exit 1
fi
LINK=$(readlink -f "$TARGET")
if [ "$LINK" != "$SOURCE" ]; then
  printf 'Refusing to remove a link to a different location: %s\n' "$LINK" >&2
  exit 1
fi
rm -- "$TARGET"
printf 'Removed local plugin symlink. The project files were left untouched.\n'
