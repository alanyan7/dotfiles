#!/usr/bin/env bash
# Install vim (if missing), the vimrc + solarized colors, and Vundle plugins.
# Safe to re-run.
set -euo pipefail

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
error() { printf '\033[1;31m==> %s\033[0m\n' "$*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

# Don't let `brew install` or apt ask questions when this script runs on its own.
export NONINTERACTIVE=1 HOMEBREW_NO_ASK=1 DEBIAN_FRONTEND=noninteractive
SUDO=sudo; [ "$(id -u)" -eq 0 ] && SUDO=""

# ── vim ── (macOS ships it; minimal Linux images often don't)
if ! command -v vim >/dev/null 2>&1; then
  info "Installing vim..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install vim
  elif command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -qq
    $SUDO apt-get install -y vim
  elif command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y vim-enhanced
  elif command -v yum >/dev/null 2>&1; then
    $SUDO yum install -y vim-enhanced
  elif command -v pacman >/dev/null 2>&1; then
    $SUDO pacman -Sy --noconfirm vim
  else
    error "No supported package manager found. Please install vim manually."
    exit 1
  fi
fi

# ── color mapping ──
mkdir -p ~/.vim/colors
cp "$SCRIPT_DIR/solarized.vim" ~/.vim/colors/solarized.vim

# ── vimrc + Vundle ──
info "Copying .vimrc..."
cp "$SCRIPT_DIR/.vimrc" ~/.vimrc
if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
  info "Installing Vundle..."
  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
else
  info "Vundle already installed, skipping."
fi

# ── plugins ── (silent Ex mode: no editor UI, works without a terminal)
info "Installing vim plugins..."
vim -E -s -u ~/.vimrc +PluginInstall +qall </dev/null
