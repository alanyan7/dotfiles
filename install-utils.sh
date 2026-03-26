#!/usr/bin/env bash
set -euo pipefail

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
warn()  { printf '\033[1;33m==> %s\033[0m\n' "$*"; }

# ── Package manager helpers ──

brew_install() {
  if command -v brew >/dev/null 2>&1; then
    brew install "$@"
  else
    warn "Homebrew not found — skipping $*. Install Homebrew first: https://brew.sh"
    return 1
  fi
}

apt_install() {
  sudo apt-get install -y "$@"
}

linux_install() {
  local pkg="$1"
  local alt="${2:-$1}"  # alternate package name if different across managers
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y "$pkg"
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y "$alt"
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm "$pkg"
  else
    warn "No supported package manager found — skipping $pkg"
    return 1
  fi
}

install_if_missing() {
  local cmd="$1"
  local desc="$2"
  shift 2
  # remaining args: install function
  if command -v "$cmd" >/dev/null 2>&1; then
    info "$desc already installed, skipping."
    return 0
  fi
  info "Installing $desc..."
  "$@"
}

# ── Update package index once on Linux ──

if [[ "$OSTYPE" != "darwin"* ]]; then
  if command -v apt-get >/dev/null 2>&1; then
    info "Updating apt package index..."
    sudo apt-get update -qq
  fi
fi

# ── fzf (fuzzy finder) ──

if ! command -v fzf >/dev/null 2>&1; then
  info "Installing fzf..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew_install fzf
    # Install keybindings and completion
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
  fi
else
  info "fzf already installed, skipping."
fi

# ── ripgrep (fast grep) ──

if [[ "$OSTYPE" == "darwin"* ]]; then
  install_if_missing rg "ripgrep" brew_install ripgrep
else
  install_if_missing rg "ripgrep" linux_install ripgrep
fi

# ── fd (fast find) ──

if [[ "$OSTYPE" == "darwin"* ]]; then
  install_if_missing fd "fd" brew_install fd
else
  # On Debian/Ubuntu the binary is fdfind, package is fd-find
  if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
    info "Installing fd..."
    linux_install fd-find fd
    # Create fd symlink on Debian/Ubuntu where the binary is named fdfind
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
      info "Created symlink: fd -> fdfind"
    fi
  else
    info "fd already installed, skipping."
  fi
fi

# ── bat (cat with syntax highlighting) ──

if [[ "$OSTYPE" == "darwin"* ]]; then
  install_if_missing bat "bat" brew_install bat
else
  if ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1; then
    info "Installing bat..."
    linux_install bat
    # On Debian/Ubuntu the binary is batcat
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
      info "Created symlink: bat -> batcat"
    fi
  else
    info "bat already installed, skipping."
  fi
fi

# ── eza (modern ls) ──

if [[ "$OSTYPE" == "darwin"* ]]; then
  install_if_missing eza "eza" brew_install eza
else
  if ! command -v eza >/dev/null 2>&1; then
    info "Installing eza..."
    # eza is not in older distro repos; try cargo or direct install
    if command -v apt-get >/dev/null 2>&1; then
      # eza has an official apt repo for Debian/Ubuntu
      if ! apt-cache show eza >/dev/null 2>&1; then
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
        sudo apt-get update -qq
      fi
      sudo apt-get install -y eza || warn "Could not install eza — skipping."
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --noconfirm eza
    else
      warn "Could not install eza — install manually or via cargo: cargo install eza"
    fi
  else
    info "eza already installed, skipping."
  fi
fi

# ── delta (better git diffs) ──

if [[ "$OSTYPE" == "darwin"* ]]; then
  install_if_missing delta "git-delta" brew_install git-delta
else
  install_if_missing delta "git-delta" linux_install git-delta git-delta
fi

# ── zoxide (smart cd) ──

if [[ "$OSTYPE" == "darwin"* ]]; then
  install_if_missing zoxide "zoxide" brew_install zoxide
else
  if ! command -v zoxide >/dev/null 2>&1; then
    info "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
  else
    info "zoxide already installed, skipping."
  fi
fi

# ── tldr (simplified man pages) ──

if [[ "$OSTYPE" == "darwin"* ]]; then
  install_if_missing tldr "tldr" brew_install tldr
else
  install_if_missing tldr "tldr" linux_install tldr
fi

info "CLI utilities installation complete."
