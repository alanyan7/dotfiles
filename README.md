# dotfiles

Dev environment setup. Tested on macOS and Linux (Debian/Ubuntu, Fedora, Arch).

## What's included

- **Homebrew** on macOS, installed first if missing (needs your password once; also provides git on a bare Mac)
- **zsh** with [Oh My Zsh](https://ohmyz.sh/), custom plugins (autosuggestions, syntax highlighting, navigation tools), and the `tjkirch` theme; made the login shell on Linux
- **GitHub CLI** (`gh`); sign in afterwards with `gh auth login`
- **tmux** with mouse support, vim-aware pane navigation, and intuitive split bindings
- **vim** with Vundle plugins and solarized colors
- **Claude Code** (installed if missing) and its config: `CLAUDE.md`, personal skills, statusline, and `settings.json`
- **[autonomOS](https://github.com/aterrylu/autonomOS)** via its official installer (plus Node.js 20+ if missing: Homebrew on macOS, the official build in `~/.local` on Linux); runs as a background service and prints the dashboard URL and token

## Quick install (one-liner)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alanyan7/dotfiles/master/install.sh)
```

This works on a bare machine (macOS, or Linux with apt, dnf/yum or pacman): it installs git if needed, clones the repo to `~/.dotfiles` (if not already present) and runs the full setup without prompts. No authentication required.

The only things it can't do for you:

- **Your password**, asked once: by Homebrew on macOS, or by `sudo` for packages on Linux (not needed when running as root).
- **Signing in** afterwards: run `claude` once (autonomOS needs it), and `gh auth login`.

## Manual install

```bash
git clone https://github.com/alanyan7/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## Partial install

Run individual installers if you only want some components:

```bash
./install-brew.sh             # Homebrew (macOS only; asks for your password)
./install-gh.sh               # GitHub CLI
./install-tmux.sh             # tmux + config
./install-vim.sh              # vim (if missing) + Vundle plugins
./install-claude.sh           # Claude Code config (missing files only)
./install-claude.sh --force   # Claude Code config (overwrite existing)
./install-autonomos.sh        # autonomOS (skips if already installed)
```

## Claude Code config

If `claude` isn't on PATH or in `~/.local/bin`, `install-claude.sh` installs it first with the official installer.

`install-claude.sh` is conservative by default — it only installs files that don't already exist on the target machine. Pass `--force` to overwrite (the existing `~/.claude/settings.json` is backed up first).

What it installs:

- `~/.claude/CLAUDE.md` — global behavioral guidelines (Karpathy-inspired)
- `~/.claude/skills/<name>/` — personal skills
- `~/.claude/statusline-command.sh` — statusline script
- `~/.claude/settings.json` — preferences (theme, hooks, permissions)

After install, sign in with `claude auth login` and restart any running Claude Code sessions.

## Customization

Local shell customizations live in `~/.zshrc.local`, which is sourced at the end of `.zshrc`. Edit this file to add your own aliases, functions, or tool config. Re-running `install.sh` will overwrite it from the repo copy, so commit personal changes there.

## References

- [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)
- [Keegan Lowenstein: tmux and vim](https://www.bugsnag.com/blog/tmux-and-vim)
