#!/usr/bin/env bash
# Install autonomOS (https://github.com/aterrylu/autonomOS) with its official
# installer: a pre-built server bundle in ~/.local/share/autonomos plus a
# background service (launchd / systemd-user) that starts at login.
# Skips if autonomOS is already installed (update with `autonomos upgrade`).
#
# Needs Node 20+ (installed if missing: Homebrew on macOS, the official build
# in ~/.local on Linux) and Claude Code (installed by install-claude.sh).
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
    [ "$(node -e 'console.log(process.versions.node.split(".")[0])' 2>/dev/null)" -ge 20 ] 2>/dev/null
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
    # Distro packages are often older than 20 (Debian 12, Ubuntu 24.04 ship
    # 18), so use the official LTS build, unpacked into ~/.local/node and
    # linked into ~/.local/bin (a folder the autonomOS service searches).
    case "$(uname -m)" in
      x86_64)        arch=x64 ;;
      aarch64|arm64) arch=arm64 ;;
      *) error "No official Node.js build for $(uname -m). Install Node 20+ manually, then re-run."; exit 1 ;;
    esac
    # index.json lists releases newest first; take the first LTS one. awk
    # reads to the end (head would close the pipe early, and with pipefail
    # the SIGPIPE upstream fails the script).
    version="$(curl -fsSL https://nodejs.org/dist/index.json | tr '{' '\n' \
      | grep -v '"lts":false' | grep -o '"version":"v[0-9.]*"' | awk -F'"' 'NR==1 {print $4}')"
    tarball="node-$version-linux-$arch.tar.gz"
    info "Installing Node.js $version to ~/.local/node..."
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/$tarball" "https://nodejs.org/dist/$version/$tarball"
    expected="$(curl -fsSL "https://nodejs.org/dist/$version/SHASUMS256.txt" | grep " $tarball\$" | cut -d' ' -f1)"
    actual="$(sha256sum "$tmp/$tarball" | cut -d' ' -f1)"
    if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
      error "Checksum mismatch for $tarball; not installing."
      exit 1
    fi
    rm -rf ~/.local/node && mkdir -p ~/.local/node ~/.local/bin
    tar -xzf "$tmp/$tarball" -C ~/.local/node --strip-components=1
    rm -rf "$tmp"
    for b in node npm npx corepack; do ln -sf ~/.local/node/bin/$b ~/.local/bin/$b; done
    hash -r
  fi
  if ! node_ok; then
    error "Node.js 20+ still not found after installing it."
    exit 1
  fi
fi

# ── autonomOS ──
info "Installing autonomOS..."
curl -fsSL https://autonomos.terrylu.cloud/install.sh | bash
