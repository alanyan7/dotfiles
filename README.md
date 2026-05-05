# dotfiles

Dev environment setup. Tested on macOS and Linux (Debian/Ubuntu, Fedora, Arch).

## What's included

- **zsh** with [Oh My Zsh](https://ohmyz.sh/), custom plugins (autosuggestions, syntax highlighting, navigation tools), and the `tjkirch` theme
- **tmux** with mouse support, vim-aware pane navigation, and intuitive split bindings
- **vim** with Vundle plugins and solarized colors
- **Claude Code config**: `CLAUDE.md`, personal skills, statusline, and `settings.json`

## Quick install (one-liner)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ComeOnGetMe/dotfiles/master/install.sh)
```

This clones the repo to `~/.dotfiles` (if not already present) and runs the full setup. No authentication required.

## Manual install

```bash
git clone https://github.com/ComeOnGetMe/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## Partial install

Run individual installers if you only want some components:

```bash
./install-tmux.sh             # tmux + config
./install-vim.sh              # vim + Vundle plugins
./install-claude.sh           # Claude Code config (missing files only)
./install-claude.sh --force   # Claude Code config (overwrite existing)
```

## Claude Code config

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
