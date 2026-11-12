# dotfiles

Dev environment setup. Tested on macOS and Linux (Debian/Ubuntu, Fedora, Arch).

## What's included

- **Homebrew** on macOS, installed first if missing (needs your password once; also provides git on a bare Mac)
- **zsh** with [Oh My Zsh](https://ohmyz.sh/), custom plugins (autosuggestions, syntax highlighting, navigation tools), and the `tjkirch` theme; made the login shell on Linux
- **GitHub CLI** (`gh`); sign in afterwards with `gh auth login`
- **tmux** with mouse support, vim-aware pane navigation, and intuitive split bindings
- **vim** with Vundle plugins and solarized colors
- **Claude Code** (installed if missing) and its config: `CLAUDE.md`, personal skills, agent personas (multi-agent org), statusline, and `settings.json`
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
./install-claude.sh --link    # symlink agent personas so edits land in this repo
./install-autonomos.sh        # autonomOS (skips if already installed)
```

## Claude Code config

If `claude` isn't on PATH or in `~/.local/bin`, `install-claude.sh` installs it first with the official installer.

`install-claude.sh` is conservative by default — it only installs files that don't already exist on the target machine. Pass `--force` to overwrite (the existing `~/.claude/settings.json` is backed up first).

What it installs:

- `~/.claude/CLAUDE.md` — global behavioral guidelines (Karpathy-inspired)
- `~/.claude/skills/<name>/` — personal skills
- `~/.claude/agents/<name>.md` — agent personas for a multi-agent org (see below); `--link` symlinks them to this repo instead of copying
- `~/.claude/statusline-command.sh` — statusline script
- `~/.claude/settings.json` — preferences (theme, hooks, permissions)

After install, sign in with `claude auth login` and restart any running Claude Code sessions.

### Multi-agent org

`claude/agents/` defines a small org of Claude Code sessions, each in its own git worktree:

- `chief-of-staff.md` — the one session you talk to, always named **Zaq** (`CoS · Zaq`); routes work, never builds
- `eng-lead.md` — plans architecture, splits work into features, starts and reviews workers (`L · <Name>: <topic>`)
- `feature-worker.md` — builds one feature or fix in its own worktree and opens one PR (`W · <Name>: <topic>`)

Machine- or employer-specific details (which repos, PR target branches, ticket tracker and chat tools, the live list of session names in use) go in `~/.claude/agent-org.local.md`, which every persona reads if present. It is never committed here. Install with `--link` to keep improving the personas from any session and commit the changes in this repo.

## Customization

Local shell customizations live in `~/.zshrc.local`, which is sourced at the end of `.zshrc`. Edit this file to add your own aliases, functions, or tool config. Re-running `install.sh` will overwrite it from the repo copy, so commit personal changes there.

## References

- [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)
- [Keegan Lowenstein: tmux and vim](https://www.bugsnag.com/blog/tmux-and-vim)
