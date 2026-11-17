#!/usr/bin/env sh
set -eu

SOURCE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLUGIN_ID="enochlawrence.yutaro-assistant"
PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins"
TARGET="$PLUGINS_DIR/$PLUGIN_ID"
MARKER="$TARGET/.yutaro-linux-local-install"
UPDATE=0

if [ "${1:-}" = "--update" ]; then
  UPDATE=1
  shift
fi
if [ "$#" -ne 0 ]; then
  printf 'Usage: %s [--update]\n' "$0" >&2
  exit 2
fi

mkdir -p "$PLUGINS_DIR"
if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  if [ -L "$TARGET" ] || [ ! -d "$TARGET" ] || [ ! -f "$MARKER" ] || [ "$(cat "$MARKER")" != "$SOURCE" ]; then
    printf 'Refusing to replace unmanaged path: %s\n' "$TARGET" >&2
    exit 1
  fi
  if [ "$UPDATE" -ne 1 ]; then
    printf 'Managed copy already exists; use %s --update to refresh it.\n' "$0"
    exit 1
  fi
  CREATED=0
else
  mkdir "$TARGET"
  CREATED=1
fi

if ! python3 - "$SOURCE" "$TARGET" <<'PY'
import shutil
import sys
from pathlib import Path

source, target = map(Path, sys.argv[1:])
ignored = {".git", "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache"}
for item in source.iterdir():
    if item.name in ignored or item.name == ".yutaro-linux-local-install" or item.suffix in {".pyc", ".pyo"}:
        continue
    destination = target / item.name
    if item.is_dir():
        shutil.copytree(item, destination, symlinks=False, dirs_exist_ok=True)
    else:
        shutil.copy2(item, destination, follow_symlinks=True)
PY
then
  if [ "$CREATED" -eq 1 ]; then rm -r -- "$TARGET"; fi
  exit 1
fi

if [ "$CREATED" -eq 1 ]; then printf '%s\n' "$SOURCE" > "$MARKER"; fi
if command -v omarchy >/dev/null 2>&1; then
  if ! omarchy plugin validate "$TARGET"; then
    if [ "$CREATED" -eq 1 ]; then rm -r -- "$TARGET"; fi
    exit 1
  fi
fi

if [ "$CREATED" -eq 1 ]; then
  printf 'Installed managed copy at %s\n' "$TARGET"
  printf 'Enable it with: omarchy plugin enable %s --section right\n' "$PLUGIN_ID"
else
  printf 'Updated managed copy at %s\n' "$TARGET"
fi
