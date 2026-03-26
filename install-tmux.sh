#!/usr/bin/env bash
set -euo pipefail

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
warn()  { printf '\033[1;33m==> %s\033[0m\n' "$*"; }
error() { printf '\033[1;31m==> %s\033[0m\n' "$*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

# ── Install tmux ──

if ! command -v tmux >/dev/null 2>&1; then
  info "Installing tmux..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew >/dev/null 2>&1; then
      error "Homebrew is required to install tmux on macOS."
      error "Install it first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
      exit 1
    fi
    brew install tmux
  else
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -qq
      sudo apt-get install -y tmux
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y tmux
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --noconfirm tmux
    else
      error "No supported package manager found. Please install tmux manually."
      exit 1
    fi
  fi
else
  info "tmux already installed, skipping."
fi

# ── Install config ──

info "Copying .tmux.conf..."
cp "$SCRIPT_DIR/.tmux.conf" ~/.tmux.conf

# Reload only if a tmux server is already running.
if tmux ls >/dev/null 2>&1; then
  tmux source-file ~/.tmux.conf
  info "tmux config reloaded."
else
  info "tmux is not running; config will be loaded next time tmux starts."
fi
