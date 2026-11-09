#!/usr/bin/env bash
# Install autonomOS (https://github.com/aterrylu/autonomOS) with its official
# installer: a pre-built server bundle in ~/.local/share/autonomos plus a
# background service (launchd / systemd-user) that starts at login.
# Skips if autonomOS is already installed (update with `autonomos upgrade`).
#
# Needs Node 20+ (installed via Homebrew on macOS if missing) and Claude Code.
set -euo pipefail

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
error() { printf '\033[1;31m==> %s\033[0m\n' "$*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

# Don't let `brew install` ask [y/n].
export NONINTERACTIVE=1 HOMEBREW_NO_ASK=1

# Node and claude may live in ~/.local/bin, which may not be on PATH yet.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

if command -v autonomos >/dev/null 2>&1; then
  info "autonomOS already installed, skipping (update with: autonomos upgrade)."
  exit 0
fi

# ── Node 20+ ──
node_ok() {
  command -v node >/dev/null 2>&1 &&
    [ "$(node -e 'console.log(process.versions.node.split(".")[0])')" -ge 20 ]
}

if ! node_ok; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    info "Installing Node.js..."
    if ! command -v brew >/dev/null 2>&1; then
      "$SCRIPT_DIR/install-brew.sh"
      for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$b" ]; then eval "$("$b" shellenv)"; break; fi
      done
    fi
    brew install node
  else
    error "autonomOS needs Node.js 20 or newer. Install it, then re-run this script:"
    error "  https://nodejs.org/en/download/package-manager"
    exit 1
  fi
fi

# ── autonomOS ──
info "Installing autonomOS..."
curl -fsSL https://autonomos.terrylu.cloud/install.sh | bash
