#!/usr/bin/env bash
# Install personal Claude Code config: CLAUDE.md, skills, statusline, settings.
# Conservative by default — never clobbers existing files. Re-running on a
# machine that already has things set up only fills in what's missing.
#
# Pass --force (or set FORCE=1) to overwrite existing files. settings.json is
# always backed up before being overwritten.
#
# Uses `cp` only (no rsync).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SRC="$SCRIPT_DIR/claude"
DST="$HOME/.claude"

FORCE="${FORCE:-0}"
for arg in "$@"; do
  case "$arg" in
    --force|-f) FORCE=1 ;;
    -h|--help)
      cat <<USAGE
Usage: install-claude.sh [--force]

  Default: install missing files only; existing files are left untouched.
  --force: overwrite existing files (settings.json is backed up first).
USAGE
      exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
skip()  { printf '\033[1;33m--  %s\033[0m\n' "$*"; }
error() { printf '\033[1;31m==> %s\033[0m\n' "$*"; }

if [ ! -d "$SRC" ]; then
  error "Source dir not found: $SRC"
  exit 1
fi

# ── claude CLI ──
# Native build installs into ~/.local/share/claude/versions/<v>/ and symlinks
# ~/.local/bin/claude. Skip if already on PATH (use `claude install latest` to
# update later).
if command -v claude >/dev/null 2>&1; then
  CLAUDE_VERSION="$(claude --version 2>/dev/null | head -1 || echo unknown)"
  skip "claude CLI already installed ($CLAUDE_VERSION)"
else
  if ! command -v curl >/dev/null 2>&1; then
    error "curl is required to install the claude CLI."
    exit 1
  fi
  info "Installing claude CLI from https://claude.ai/install.sh"
  curl -fsSL https://claude.ai/install.sh | bash
  # Make sure ~/.local/bin is on PATH for the verification below.
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
  if command -v claude >/dev/null 2>&1; then
    info "claude installed: $(claude --version 2>/dev/null | head -1)"
  else
    error "claude install ran but the binary is not on PATH. Add ~/.local/bin to PATH and re-run."
    exit 1
  fi
fi

mkdir -p "$DST" "$DST/skills"

# ── settings.json ── (template: __HOME__ → $HOME)
if [ -f "$DST/settings.json" ] && [ "$FORCE" != "1" ]; then
  skip "settings.json already exists (pass --force to overwrite)"
else
  if [ -f "$DST/settings.json" ]; then
    BACKUP="$DST/settings.json.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$DST/settings.json" "$BACKUP"
    info "Backed up existing settings.json -> $BACKUP"
  fi
  info "Installing settings.json"
  sed "s|__HOME__|$HOME|g" "$SRC/settings.json" > "$DST/settings.json"
fi

# ── statusline-command.sh ──
if [ -f "$DST/statusline-command.sh" ] && [ "$FORCE" != "1" ]; then
  skip "statusline-command.sh already exists"
else
  info "Installing statusline-command.sh"
  cp "$SRC/statusline-command.sh" "$DST/statusline-command.sh"
  chmod +x "$DST/statusline-command.sh"
fi

# ── CLAUDE.md (global personal context) ──
if [ -f "$SRC/CLAUDE.md" ]; then
  if [ -f "$DST/CLAUDE.md" ] && [ "$FORCE" != "1" ]; then
    skip "CLAUDE.md already exists"
  else
    info "Installing CLAUDE.md"
    cp "$SRC/CLAUDE.md" "$DST/CLAUDE.md"
  fi
fi

# ── skills (one per directory) ──
info "Installing skills"
for dir in "$SRC"/skills/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  target="$DST/skills/$name"
  if [ -d "$target" ] && [ "$FORCE" != "1" ]; then
    skip "  skill already installed: $name"
    continue
  fi
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
