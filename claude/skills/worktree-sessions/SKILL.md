---
name: worktree-sessions
description: Spawn a detached tmux session running `claude --remote-control <slug>` inside a git worktree — either by creating a brand-new worktree+branch from a slug, or by attaching to an existing worktree path. INVOKE THIS SKILL — DO NOT do the work in the current session — whenever the user asks to "create another session", "spin up a session", "start a new session", "make a session", "spawn a session", "create a session for / from / with a worktree", "open another claude in a worktree", "fork off a worktree session", "launch a session for an existing worktree", or any phrasing that combines spawning a tmux/claude session with a worktree (new or existing). Output is always a detached tmux session, never inline work in the current session.
argument-hint: <slug-or-existing-worktree-path>
allowed-tools: Bash(git worktree *), Bash(git branch *), Bash(git rev-parse *), Bash(git -C *), Bash(git status *), Bash(tmux *), Bash(ls *), Bash(test *), Bash(echo *), Bash(printf *), Bash(which *), Bash(mkdir *), Bash(cp *), Bash(cat *), Bash(jq *), Bash(bash *), Bash(whoami *), Bash(realpath *), Bash(basename *), Bash(dirname *), AskUserQuestion
---

# Worktree Sessions

Spawn one detached tmux session running `claude --remote-control <slug>` inside a git worktree. `--remote-control` (vs plain `-n`) is required for the session to appear in the Claude Code desktop app. The skill works in two modes:

- **Create mode** — input is a kebab-case slug → create a new branch + new worktree at `~/.claude-worktrees/<slug>/`, then spawn the session.
- **Attach mode** — input is a path to an existing worktree → spawn a session for it (rename the directory if it has a legacy `<USER>-` prefix so the CC TUI displays the slug cleanly).

In both modes, the worktree directory basename, the tmux session name, and the Claude Code project display name (cwd basename in CC TUI / desktop app) end up matching the same `<slug>`. The branch name keeps the user prefix.

## Input

- **`<slug>`** — kebab-case (`^[a-z0-9][a-z0-9-]*$`). Triggers **create mode**.
- **`<path>`** — anything containing `/` or starting with `~`. Triggers **attach mode**. The path must be an existing directory that is registered as a git worktree.

If the user invoked the skill with no argument, ask once via AskUserQuestion: "Slug for a new worktree, or path to an existing worktree?". Don't guess from context.

Mode selection rule: if the argument contains a `/` or starts with `~`, it's a path → attach mode. Otherwise it's a slug → create mode. (If the user passes a bare directory name that happens to also be a valid slug, treat it as a slug — they should pass `./<name>` or a full path to force attach mode.)

## Naming

Let `USER=$(whoami | cut -d_ -f1)` (drop any `_` suffix, e.g. `zhipeng_yan` → `zhipeng`).

**Create mode** — given slug `<slug>`:

- Worktree directory basename = `<slug>`.
- Worktree path = `~/.claude-worktrees/<slug>/`.
- Tmux session name = `<slug>`.
- Branch name = `<USER>/<slug>` (slash separator). If the repo's convention is `<USER>-<slug>`, follow that — check `git -C <main-repo> for-each-ref --format='%(refname:short)' refs/heads | head -5` to see existing branch shape.

**Attach mode** — given path `<path>`:

- `slug = $(basename "$path")`.
- If the basename starts with `<USER>-`, strip that prefix to get the slug, and `git -C <main-repo> worktree move "$path" ~/.claude-worktrees/<slug>` to rename the directory. The branch is unchanged.
- Tmux session name = `<slug>`.
- New worktree path (if renamed) = `~/.claude-worktrees/<slug>/`. Otherwise unchanged.

## Procedure

### Common preflight

1. Validate `tmux` and `claude` are on `$PATH` (`which tmux claude`).
2. Compute the resolved `<slug>` based on mode (see "Naming" above).
3. The tmux session `<slug>` must not already exist (`tmux has-session -t <slug>` returns non-zero). If it exists, stop and report.

### Create mode

1. Validate `<slug>` is kebab-case (`^[a-z0-9][a-z0-9-]*$`).
2. The branch `<USER>/<slug>` must not already exist (`git -C <main-repo> rev-parse --verify <branch>` returns non-zero).
3. The worktree path `~/.claude-worktrees/<slug>/` must not already exist.
4. Locate the source repo. Use `git -C ~/code/dyna rev-parse --show-toplevel` if it resolves; otherwise fall back to `git rev-parse --show-toplevel` from the parent's cwd. The main checkout is the worktree directly under `~/code/` (not under `.claude-worktrees/`). If ambiguous, ask via AskUserQuestion.
5. Create the worktree:
   ```bash
   git -C <main-repo> worktree add ~/.claude-worktrees/<slug> -b <USER>/<slug>
   ```
6. Copy ignored config files. If `<main-repo>/.cursor/worktrees.json` exists, run each command from its `setup-worktree` array inside the new worktree, with `ROOT_WORKTREE_PATH=<main-repo>`. Each command is best-effort (`|| true`):
   ```bash
   cd ~/.claude-worktrees/<slug>
   export ROOT_WORKTREE_PATH=<main-repo>
   jq -r '.["setup-worktree"][]' <main-repo>/.cursor/worktrees.json | while read -r cmd; do
       bash -c "$cmd"
   done
   ```
7. Continue to "Spawn".

### Attach mode

1. Resolve the path: expand `~` and run `realpath` to get an absolute path.
2. The path must be a directory (`test -d`).
3. The path must be registered as a git worktree:
   ```bash
   git -C <main-repo> worktree list --porcelain | grep -F "worktree $resolved_path"
   ```
4. The worktree must have no in-progress rebase/merge (best-effort: `git -C <path> status --porcelain=v2 --branch | head -3`). Don't block on dirty working tree — the user may want a session precisely to keep working.
5. If the basename starts with `<USER>-`:
   - Compute `target = ~/.claude-worktrees/<slug>` where `<slug>` is the stripped basename.
   - If `target` already exists, abort and ask the user to resolve the conflict.
   - Otherwise: `git -C <main-repo> worktree move <resolved_path> <target>`. Update the path variable to point to the new location.
6. Continue to "Spawn".

### Spawn (both modes)

```bash
tmux new-session -d -s <slug> -c <worktree-path> "claude --remote-control <slug>"
```

### Report

Print a compact summary, indicating which mode ran:

**Create mode:**
```
Mode:     create
Worktree: ~/.claude-worktrees/<slug>  (branch <USER>/<slug>)
Session:  tmux attach -t <slug>
```

**Attach mode:**
```
Mode:     attach
Worktree: <worktree-path>  (renamed from <old-path>)   # only if renamed
Session:  tmux attach -t <slug>
```

## Failure handling

- If worktree creation/rename succeeds but tmux fails, leave the worktree in place. Tell the user how to spawn manually: `tmux new-session -d -s <slug> -c <path> "claude --remote-control <slug>"`. Don't roll back filesystem state — the user may have intended work on it.
- If preflight validation fails (existing branch / existing session / existing path / path-not-a-worktree / collision in attach-mode rename), don't change anything; report which check failed and what to do.
- If `git worktree move` fails (e.g. uncommitted changes blocking the move on some git versions), report the error and offer to skip the rename: spawn the session at the original path instead, with the longer name as the slug.

## Notes

- Personal skill, user-scope (`~/.claude/skills/worktree-sessions/`).
- Skill changes only take effect in Claude Code sessions started **after** the change. Existing sessions need a restart to pick up new or edited skills (the slash picker / autocomplete uses the snapshot loaded at session start).
- The tmux session is detached; the parent Claude Code session keeps running. Attach with `tmux attach -t <slug>`.
- In create mode the branch is created from `HEAD` of the main checkout. Rebase onto `main` later if needed.
- One invocation → one worktree + one session. For multi-worktree fan-out, invoke the skill once per slug/path.
