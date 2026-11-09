#!/usr/bin/env bash
# Install the GitHub CLI (gh). Skips if it's already installed.
# Sign in afterwards with `gh auth login` (interactive, so not done here).
set -euo pipefail

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
error() { printf '\033[1;31m==> %s\033[0m\n' "$*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

# Don't let `brew install` ask [y/n].
export NONINTERACTIVE=1 HOMEBREW_NO_ASK=1

if command -v gh >/dev/null 2>&1; then
  info "gh already installed ($(gh --version | head -1)), skipping."
  exit 0
fi

info "Installing GitHub CLI (gh)..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    "$SCRIPT_DIR/install-brew.sh"
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [ -x "$b" ]; then eval "$("$b" shellenv)"; break; fi
    done
  fi
  brew install gh
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo apt-get install -y gh
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y gh
elif command -v yum >/dev/null 2>&1; then
  sudo yum install -y gh
elif command -v pacman >/dev/null 2>&1; then
  sudo pacman -Sy --noconfirm github-cli
else
  error "No supported package manager found. Install gh manually: https://cli.github.com"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  error "gh install finished but gh was not found on PATH."
  exit 1
fi
info "gh installed: $(gh --version | head -1)"
info "Sign in with: gh auth login"
