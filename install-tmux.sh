set -x

real_dir=$(cd "$(dirname "$0")"; pwd -P)

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  if ! command -v tmux >/dev/null 2>&1; then
    brew install tmux
  fi
else
  # Linux
  if ! command -v tmux >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y tmux
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y tmux
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --noconfirm tmux
    else
      echo "No supported package manager found. Please install tmux manually."
      exit 1
    fi
  fi
fi

# tmux configs
cp "$real_dir/.tmux.conf" ~/.tmux.conf

# Tmux reads `~/.tmux.conf` when the tmux *server starts*.
# Reload only if a tmux server is already running.
if tmux ls >/dev/null 2>&1; then
  tmux source-file ~/.tmux.conf
else
  echo "tmux is not running; config will be loaded next time tmux starts."
fi
