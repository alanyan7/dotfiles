#!/usr/bin/env bash
set -euo pipefail

# ── Bootstrap: support both local and remote (curl | bash) execution ──
DOTFILES_REPO="https://github.com/ComeOnGetMe/dotfiles.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# When piped from curl, BASH_SOURCE is empty — clone the repo first.
# When run as ./install.sh from inside the repo, skip straight ahead.
if [ -z "${BASH_SOURCE[0]:-}" ] || [ ! -f "$(dirname "${BASH_SOURCE[0]}")/install-tmux.sh" ]; then
  echo "==> Bootstrapping: cloning dotfiles into $DOTFILES_DIR"
  if [ ! -d "$DOTFILES_DIR" ]; then
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  cd "$DOTFILES_DIR"
else
  cd "$(dirname "${BASH_SOURCE[0]}")"
fi

SCRIPT_DIR="$(pwd -P)"

# ── Non-interactive: assume yes everywhere ──
# HOMEBREW_NO_ASK stops `brew install` asking [y/n] (ask mode is on by default
# in newer Homebrew). Exported, so the sub-installers inherit both.
export NONINTERACTIVE=1 HOMEBREW_NO_ASK=1

# ── Helpers ──

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
warn()  { printf '\033[1;33m==> %s\033[0m\n' "$*"; }
error() { printf '\033[1;31m==> %s\033[0m\n' "$*"; }

# Portable sed in-place (BSD vs GNU)
sedi() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# ── Prerequisite checks ──

if ! command -v git >/dev/null 2>&1; then
  error "git is required but not installed. Please install git first."
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  error "curl is required but not installed. Please install curl first."
  exit 1
fi

# Claude Code is expected to be installed already; check before changing
# anything so a missing CLI doesn't leave a half-finished setup.
# The native installer puts it in ~/.local/bin, which may not be on PATH yet.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
if ! command -v claude >/dev/null 2>&1; then
  error "Claude Code (claude) is required but not installed."
  error "Install it first, then re-run this script:"
  error "  curl -fsSL https://claude.ai/install.sh | bash"
  exit 1
fi

# ── Homebrew (macOS) ──
# Installed up front so later steps (zsh, tmux) can use it. Exported PATH
# reaches the sub-installers too.

load_brew() {
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$b" ]; then eval "$("$b" shellenv)"; return 0; fi
  done
}

if [[ "$OSTYPE" == "darwin"* ]]; then
  "$SCRIPT_DIR/install-brew.sh"
  load_brew
fi

# Ensure zsh is available
if ! command -v zsh >/dev/null 2>&1; then
  info "Installing zsh..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install zsh
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y zsh
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y zsh
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm zsh
  else
    error "Could not install zsh. Please install it manually."
    exit 1
  fi
fi

# ── Oh My Zsh ──

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  info "Oh My Zsh already installed, skipping."
fi

# ── ZSH theme ──

if grep -q 'ZSH_THEME="robbyrussell"' ~/.zshrc 2>/dev/null; then
  info "Setting ZSH theme to tjkirch..."
  sedi -e 's/ZSH_THEME.*/ZSH_THEME="tjkirch"/' ~/.zshrc
else
  info "ZSH theme already customized, skipping."
fi

# ── ZSH plugins ──

PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
mkdir -p "$PLUGIN_DIR"

clone_plugin() {
  local repo="$1" name="$2"
  if [ ! -d "$PLUGIN_DIR/$name" ]; then
    info "Installing plugin: $name"
    git clone "$repo" "$PLUGIN_DIR/$name"
  else
    info "Plugin $name already installed, skipping."
  fi
}

clone_plugin https://github.com/zsh-users/zsh-autosuggestions zsh-autosuggestions
clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting zsh-syntax-highlighting
clone_plugin https://github.com/psprint/zsh-navigation-tools zsh-navigation-tools

# Add plugins to .zshrc if not already present
if ! grep -q 'zsh-autosuggestions' ~/.zshrc 2>/dev/null; then
  info "Adding plugins to .zshrc..."
  sedi -e '/^plugins=/s/)$/\n  zsh-autosuggestions\n  zsh-navigation-tools\n  zsh-syntax-highlighting\n  z)/' ~/.zshrc
  touch ~/.z
else
  info "Plugins already in .zshrc, skipping."
fi

# ── Source local customizations file ──

ZSHRC_LOCAL="$HOME/.zshrc.local"

# Ensure .zshrc sources the local file
if ! grep -qF '.zshrc.local' ~/.zshrc 2>/dev/null; then
  info "Adding .zshrc.local source hook to .zshrc..."
  printf '\n# Local customizations\n[ -f ~/.zshrc.local ] && source ~/.zshrc.local\n' >> ~/.zshrc
fi

# Install/update the local customizations file
info "Installing .zshrc.local..."
cp "$SCRIPT_DIR/zshrc.local" "$ZSHRC_LOCAL"

# ── Sub-installers ──

info "Installing tmux..."
"$SCRIPT_DIR/install-tmux.sh"

info "Installing GitHub CLI..."
"$SCRIPT_DIR/install-gh.sh"

info "Installing Claude Code config..."
"$SCRIPT_DIR/install-claude.sh"

# ── Done ──

echo ""
info "Installation complete!"
info "Run 'source ~/.zshrc' or start a new shell to apply changes."
