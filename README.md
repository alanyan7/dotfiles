# dotfiles

Dev environment setup. Tested on macOS and Linux (Debian/Ubuntu, Fedora, Arch).

## What's included

- **zsh** with [Oh My Zsh](https://ohmyz.sh/), custom plugins (autosuggestions, syntax highlighting, navigation tools), and the `tjkirch` theme
- **tmux** with mouse support, vim-aware pane navigation, and intuitive split bindings
- **CLI utilities**: fzf, ripgrep, fd, bat, eza, git-delta, zoxide, tldr
- **vim** with Vundle plugins and solarized colors

## Quick install (one-liner)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zhipeng-yan/dotfiles/master/install.sh)
```

This clones the repo to `~/.dotfiles` (if not already present) and runs the full setup.

## Manual install

```bash
git clone https://github.com/zhipeng-yan/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## Partial install

Run individual installers if you only want some components:

```bash
./install-tmux.sh    # tmux + config
./install-utils.sh   # CLI utilities (fzf, ripgrep, fd, bat, eza, delta, zoxide, tldr)
./install-vim.sh     # vim + Vundle plugins
```

## What gets installed

| Tool | Replaces | Purpose |
|------|----------|---------|
| [fzf](https://github.com/junegunn/fzf) | - | Fuzzy finder for files, history, etc. |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `grep` | Fast regex search |
| [fd](https://github.com/sharkdp/fd) | `find` | Fast file finder |
| [bat](https://github.com/sharkdp/bat) | `cat` | Syntax-highlighted file viewer |
| [eza](https://github.com/eza-community/eza) | `ls` | Modern file listing with git status |
| [git-delta](https://github.com/dandavison/delta) | `diff` | Better git diffs |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `cd`/`z` | Smart directory jumping |
| [tldr](https://github.com/tldr-pages/tldr) | `man` | Simplified command examples |

## Customization

Local shell customizations live in `~/.zshrc.local`, which is sourced at the end of `.zshrc`. Edit this file to add your own aliases, functions, or tool config. Re-running `install.sh` will overwrite it from the repo copy, so commit personal changes there.

## References

- [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)
- [Keegan Lowenstein: tmux and vim](https://www.bugsnag.com/blog/tmux-and-vim)
