#!/usr/bin/env bash
# Install personal Claude Code config: skills, statusline, settings.
# Uses `cp` (no rsync). Idempotent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SRC="$SCRIPT_DIR/claude"
DST="$HOME/.claude"

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
warn()  { printf '\033[1;33m==> %s\033[0m\n' "$*"; }
error() { printf '\033[1;31m==> %s\033[0m\n' "$*"; }

if [ ! -d "$SRC" ]; then
  error "Source dir not found: $SRC"
  exit 1
fi

mkdir -p "$DST"

# Back up existing settings.json so we never lose hand-edits.
if [ -f "$DST/settings.json" ]; then
  BACKUP="$DST/settings.json.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$DST/settings.json" "$BACKUP"
  info "Backed up existing settings.json -> $BACKUP"
fi

# Render settings.json: substitute __HOME__ -> $HOME.
info "Installing settings.json"
sed "s|__HOME__|$HOME|g" "$SRC/settings.json" > "$DST/settings.json"

# Statusline script.
info "Installing statusline-command.sh"
cp "$SRC/statusline-command.sh" "$DST/statusline-command.sh"
chmod +x "$DST/statusline-command.sh"

# Skills (one-by-one so we don't blow away unrelated user skills).
info "Installing skills"
mkdir -p "$DST/skills"
for dir in "$SRC"/skills/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  target="$DST/skills/$name"
  if [ -d "$target" ]; then
    info "  refreshing skill: $name"
    rm -rf "$target"
  else
    info "  installing skill: $name"
  fi
  cp -R "$dir" "$target"
done

info "Done."
info "Restart any running Claude Code sessions to pick up changes."
