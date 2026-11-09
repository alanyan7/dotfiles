#!/usr/bin/env bash
# Install the GitHub CLI (gh). Skips if it's already installed.
# Sign in afterwards with `gh auth login` (interactive, so not done here).
set -euo pipefail

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
error() { printf '\033[1;31m==> %s\033[0m\n' "$*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

# Don't let `brew install` or apt ask questions.
export NONINTERACTIVE=1 HOMEBREW_NO_ASK=1 DEBIAN_FRONTEND=noninteractive
SUDO=sudo; [ "$(id -u)" -eq 0 ] && SUDO=""

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
  $SUDO apt-get update -qq
  if ! $SUDO apt-get install -y gh; then
    # Older Debian/Ubuntu don't package gh; use GitHub's own apt repository.
    info "gh not in the default repositories; adding GitHub's apt repository..."
    $SUDO mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | $SUDO tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    $SUDO chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | $SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    $SUDO apt-get update -qq
    $SUDO apt-get install -y gh
  fi
elif command -v dnf >/dev/null 2>&1; then
  $SUDO dnf install -y gh
elif command -v yum >/dev/null 2>&1; then
  $SUDO yum install -y gh
elif command -v pacman >/dev/null 2>&1; then
  $SUDO pacman -Sy --noconfirm github-cli
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
