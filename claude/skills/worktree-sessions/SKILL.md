---
name: worktree-sessions
description: Spawn a detached tmux session running `claude --remote-control <slug>` inside a git worktree — either by creating a brand-new worktree+branch from a slug, attaching to an existing worktree path, or checking out an existing branch. INVOKE THIS SKILL — DO NOT do the work in the current session — whenever the user asks to "create another session", "spin up a session", "start a new session", "make a session", "spawn a session", "create a session for / from / with a worktree", "open another claude in a worktree", "fork off a worktree session", "launch a session for an existing worktree", or any phrasing that combines spawning a tmux/claude session with a worktree (new or existing). Output is always a detached tmux session, never inline work in the current session.
argument-hint: <slug | branch | existing-worktree-path> [--push] [--no-session]
allowed-tools: Bash(bash *), Bash(which *), Bash(tmux *), Bash(git -C *), Bash(git worktree *), Bash(git rev-parse *), Bash(realpath *), Bash(basename *), Bash(jq *), Bash(cp *), Bash(mkdir *), AskUserQuestion
---

# Worktree Sessions

All the logic lives in a script **bundled with this skill**: `worktree-session.sh` (next to this file). This skill is a thin wrapper — just run the script and report its output.

The script spawns one detached tmux session running `claude --remote-control <slug>` inside a git worktree. `--remote-control` makes the session show up in the Claude Code desktop app. The worktree directory basename, the tmux session name, and the CC project display name all match `<slug>`.

## Procedure

1. If the user gave **no argument**, ask once via AskUserQuestion: "Slug for a new worktree, a branch name, or a path to an existing worktree?". Don't guess.
2. Run the bundled script with the argument verbatim, plus any flags the user asked for. The script lives in this skill's directory (the harness announces it as "Base directory for this skill" on invocation; at user scope that is `~/.claude/skills/worktree-sessions/`):
   ```bash
   bash ~/.claude/skills/worktree-sessions/worktree-session.sh "<arg>"            # create / attach / branch — auto-detected
   bash ~/.claude/skills/worktree-sessions/worktree-session.sh "<branch>" --push  # also push the branch to origin
   ```
3. Relay the script's summary to the user (Mode / Worktree / branch / `tmux attach -t <slug>`). If it exits non-zero, report the error it printed — don't retry blindly.

That's it. The script handles everything below on its own; you do **not** need to run the individual git/tmux steps.

## What the script does (for reference)

- **Mode auto-detection** from the single argument:
  - kebab-case slug (`^[a-z0-9][a-z0-9-]*$`) → **create** branch `<USER>/<slug>` from the primary worktree's HEAD.
  - an existing local/remote **branch** (e.g. `zhipeng/foo`) → worktree that checks out / tracks it (slug = branch basename).
  - an existing worktree **path** (contains `/` or `~` and is a real dir) → **attach**; a legacy `<USER>-` dir prefix is renamed to a clean slug.
- **Idempotent**: if the session already exists it reports and exits 0; if the worktree already exists it just (re)spawns the session (no duplicate branch/worktree).
- `USER` prefix = `$(whoami | cut -d_ -f1)`; override with `WORKTREE_USER`.
- Copies ignored config via `<repo>/.cursor/worktrees.json` `setup-worktree`.
- **Auto-dismisses** Claude's startup "Settings Warning" prompt so the detached session doesn't hang/die on launch.
- Verifies the pane is alive after spawn; if the session command exited, prints its last output and fails.

Flags: `--push` (push branch to origin if not there yet), `--no-session` (prepare worktree only), `--dry-run`, `-h`.
Env overrides: `WORKTREE_BASE` (default `~/.claude-worktrees`), `WORKTREE_REPO` (default `~/code/dyna`, else cwd repo), `WORKTREE_USER`, `WORKTREE_SESSION_CMD` (default `claude --remote-control`).

## Notes

- The script is installed alongside the skill by `~/code/dotfiles/install-claude.sh` (`cp -R` of the skill dir). It is **not** a global command on `$PATH` — call it by path as shown above. If you ever want a terminal command, symlink it into `~/.local/bin/`.
- Skill/script changes only take effect in Claude Code sessions started **after** the change.
- The tmux session is detached; the parent session keeps running. Attach with `tmux attach -t <slug>`.
- One invocation → one worktree + one session. For multi-worktree fan-out, invoke once per arg.
