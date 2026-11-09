#!/usr/bin/env bash
# Install Homebrew on macOS if it isn't already present, and make sure login
# shells put it on PATH. No-op on other platforms or when brew already exists.
#
# The official installer asks for your password (sudo) once, so run this from
# an interactive terminal.
#
# Callers run this as a subprocess, so it cannot change their PATH. A caller
# that needs brew afterwards loads it itself (see load_brew in install.sh).
set -euo pipefail

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
error() { printf '\033[1;31m==> %s\033[0m\n' "$*"; }

if [[ "$OSTYPE" != "darwin"* ]]; then
  info "Not macOS; skipping Homebrew."
  exit 0
fi

# Apple Silicon installs to /opt/homebrew, Intel to /usr/local.
find_brew() {
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] && { echo "$b"; return 0; }
  done
  command -v brew 2>/dev/null
}

BREW="$(find_brew || true)"
if [ -n "$BREW" ]; then
  info "Homebrew already installed ($BREW), skipping."
else
  info "Installing Homebrew (you'll be asked for your password once)..."
  # NONINTERACTIVE skips the installer's "Press RETURN" confirmation, but in
  # that mode it fails instead of prompting for sudo — so ask for the
  # password up front and let the installer reuse the cached credential.
  sudo -v
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  BREW="$(find_brew || true)"
  if [ -z "$BREW" ]; then
    error "Homebrew install finished but brew was not found."
    exit 1
  fi
fi

# Persist for login shells (zsh reads ~/.zprofile before ~/.zshrc).
SHELLENV_LINE="eval \"\$($BREW shellenv)\""
if ! grep -qF "$BREW shellenv" ~/.zprofile 2>/dev/null; then
  info "Adding Homebrew to ~/.zprofile..."
  printf '\n# Homebrew\n%s\n' "$SHELLENV_LINE" >> ~/.zprofile
fi
