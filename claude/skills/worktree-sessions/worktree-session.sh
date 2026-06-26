#!/usr/bin/env bash
# worktree-session — create/attach a git worktree and spawn a detached
# `claude --remote-control <slug>` tmux session for it.
#
# One positional argument, mode auto-detected:
#   <slug>          kebab-case (^[a-z0-9][a-z0-9-]*$)  -> create mode
#   <branch>        an existing local/remote branch    -> worktree for that branch
#   <path>          an existing worktree directory      -> attach mode
#
# Create mode is idempotent: if the worktree already exists it just (re)spawns
# the session; if the branch already exists (local or remote) it checks it out
# instead of creating a new one; otherwise it creates <USER>/<slug> from the
# primary worktree's HEAD.
#
# Flags:
#   --push          push the branch to origin if it has no upstream yet
#   --no-session    create/prepare the worktree but do not spawn a tmux session
#   --dry-run       print the plan; make no changes
#   -h, --help      this help
#
# Env overrides (handy for testing / other setups):
#   WORKTREE_BASE         worktree parent dir   (default ~/.claude-worktrees)
#   WORKTREE_REPO         source repo           (default ~/code/dyna, else cwd repo)
#   WORKTREE_USER         branch prefix         (default $(whoami | cut -d_ -f1))
#   WORKTREE_SESSION_CMD  session command       (default "claude --remote-control")
#                         the slug is appended as the final argument
set -euo pipefail

# ── output helpers ──
info() { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
skip() { printf '\033[1;33m--  %s\033[0m\n' "$*"; }
err()  { printf '\033[1;31m==> %s\033[0m\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

usage() { sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

# ── args ──
PUSH=0 NO_SESSION=0 DRY=0 ARG=""
for a in "$@"; do
  case "$a" in
    --push)       PUSH=1 ;;
    --no-session) NO_SESSION=1 ;;
    --dry-run)    DRY=1 ;;
    -h|--help)    usage 0 ;;
    -*)           die "Unknown flag: $a" ;;
    *)            [ -z "$ARG" ] || die "Only one positional argument allowed (got '$ARG' and '$a')"; ARG="$a" ;;
  esac
done
[ -n "$ARG" ] || die "Missing argument. Pass a <slug>, <branch>, or <path>.  (-h for help)"

run() { if [ "$DRY" = 1 ]; then echo "    [dry-run] $*"; else "$@"; fi; }

# ── config ──
WORKTREE_BASE="${WORKTREE_BASE:-$HOME/.claude-worktrees}"
USER_PREFIX="${WORKTREE_USER:-$(whoami | cut -d_ -f1)}"
SESSION_CMD="${WORKTREE_SESSION_CMD:-claude --remote-control}"

command -v git  >/dev/null 2>&1 || die "git not found on PATH"
command -v tmux >/dev/null 2>&1 || die "tmux not found on PATH"

# Resolve the PRIMARY worktree of the source repo (branches are cut from its HEAD).
resolve_repo() {
  local start
  if [ -n "${WORKTREE_REPO:-}" ]; then
    start="$WORKTREE_REPO"
  elif git -C "$HOME/code/dyna" rev-parse --show-toplevel >/dev/null 2>&1; then
    start="$HOME/code/dyna"
  else
    start="$PWD"
  fi
  git -C "$start" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || die "Not inside a git repo (and no WORKTREE_REPO / ~/code/dyna found)"
  # First "worktree " line = primary worktree. Parsed in-shell (no early-exit
  # pipe, which would SIGPIPE the producer under `set -o pipefail`).
  local list line; list="$(git -C "$start" worktree list --porcelain)"
  while IFS= read -r line; do
    case "$line" in "worktree "*) printf '%s\n' "${line#worktree }"; return;; esac
  done <<< "$list"
}
MAIN="$(resolve_repo)"

branch_exists_local()  { git -C "$MAIN" show-ref --verify --quiet "refs/heads/$1"; }
branch_exists_remote() { [ -n "$(git -C "$MAIN" ls-remote --heads origin "$1" 2>/dev/null)" ]; }
is_registered_worktree() {
  local list; list="$(git -C "$MAIN" worktree list --porcelain)"
  grep -qxF "worktree $1" <<< "$list"
}

# ── mode detection ──
# slug-shaped bare token -> create; path that exists -> attach; otherwise a
# token containing '/' (or ~,/,./) is a branch if known, else error.
MODE="" SLUG="" BRANCH="" WT="" OLD_WT=""

if [[ "$ARG" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  MODE="create"
  SLUG="$ARG"
  BRANCH="$USER_PREFIX/$SLUG"
  WT="$WORKTREE_BASE/$SLUG"
else
  # expand ~ and resolve a possible path
  EXPANDED="${ARG/#\~/$HOME}"
  RESOLVED=""
  [ -e "$EXPANDED" ] && RESOLVED="$(realpath "$EXPANDED")"
  if [ -n "$RESOLVED" ] && [ -d "$RESOLVED" ]; then
    MODE="attach"
    WT="$RESOLVED"
    is_registered_worktree "$WT" || die "Path is not a registered git worktree: $WT"
    SLUG="$(basename "$WT")"
    BRANCH="$(git -C "$WT" rev-parse --abbrev-ref HEAD)"
    # strip a legacy "<USER>-" directory prefix so the CC display name is clean
    if [[ "$SLUG" == "$USER_PREFIX"-* ]]; then
      local_new="${SLUG#"$USER_PREFIX"-}"
      OLD_WT="$WT"; SLUG="$local_new"; WT="$WORKTREE_BASE/$SLUG"
      [ -e "$WT" ] && die "Rename target already exists: $WT"
    fi
  elif branch_exists_local "$ARG" || branch_exists_remote "$ARG"; then
    MODE="branch"
    BRANCH="$ARG"
    SLUG="$(basename "$ARG")"
    WT="$WORKTREE_BASE/$SLUG"
  else
    die "'$ARG' is not a kebab slug, an existing path, or a known branch."
  fi
fi

info "Mode: $MODE   slug=$SLUG   branch=$BRANCH"
info "Worktree: $WT"

# ── session-name preflight ──
if tmux has-session -t "$SLUG" 2>/dev/null; then
  if [ "$NO_SESSION" = 1 ]; then
    die "tmux session '$SLUG' already exists"
  fi
  skip "tmux session '$SLUG' already exists — nothing to do (attach: tmux attach -t $SLUG)"
  exit 0
fi

# ── ensure the worktree exists ──
ensure_worktree() {
  if [ -d "$WT" ]; then
    is_registered_worktree "$WT" || die "Path exists but is not a registered worktree: $WT"
    BRANCH="$(git -C "$WT" rev-parse --abbrev-ref HEAD)"  # report the real branch
    skip "worktree already present — reusing it (branch $BRANCH)"
    return
  fi
  run mkdir -p "$WORKTREE_BASE"
  case "$MODE" in
    attach) die "Worktree path vanished: $WT" ;;  # detected above; shouldn't happen
    *)
      if branch_exists_local "$BRANCH"; then
        info "Checking out existing local branch into a new worktree"
        run git -C "$MAIN" worktree add "$WT" "$BRANCH"
      elif branch_exists_remote "$BRANCH"; then
        info "Tracking existing remote branch origin/$BRANCH"
        run git -C "$MAIN" fetch origin "$BRANCH"
        run git -C "$MAIN" worktree add --track -b "$BRANCH" "$WT" "origin/$BRANCH"
      else
        info "Creating new branch $BRANCH from primary HEAD"
        run git -C "$MAIN" worktree add "$WT" -b "$BRANCH"
      fi ;;
  esac
}

# attach-mode directory rename (legacy "<USER>-" prefix)
if [ -n "$OLD_WT" ]; then
  info "Renaming legacy worktree dir: $OLD_WT -> $WT"
  run mkdir -p "$WORKTREE_BASE"
  run git -C "$MAIN" worktree move "$OLD_WT" "$WT"
else
  ensure_worktree
fi

# ── optional: push branch to origin ──
if [ "$PUSH" = 1 ]; then
  if branch_exists_remote "$BRANCH"; then
    skip "branch already on origin — no push needed"
  else
    info "Pushing $BRANCH to origin"
    run git -C "$WT" push -u origin "$BRANCH"
  fi
fi

# ── copy ignored config files (.cursor/worktrees.json setup-worktree) ──
copy_config() {
  local cfg="$MAIN/.cursor/worktrees.json"
  [ -f "$cfg" ] || return 0
  command -v jq >/dev/null 2>&1 || { skip "jq not found — skipping config copy"; return 0; }
  info "Copying ignored config files"
  ( cd "$WT" && export ROOT_WORKTREE_PATH="$MAIN"
    jq -r '.["setup-worktree"][]?' "$cfg" | while read -r cmd; do bash -c "$cmd" || true; done )
}
[ "$DRY" = 1 ] || copy_config

# ── spawn the session ──
if [ "$NO_SESSION" = 1 ]; then
  info "Worktree ready (--no-session): $WT"
  exit 0
fi

spawn_session() {
  if [ "$DRY" = 1 ]; then echo "    [dry-run] tmux new-session -d -s $SLUG -c $WT \"$SESSION_CMD $SLUG\""; return; fi
  tmux new-session -d -s "$SLUG" -c "$WT" "$SESSION_CMD $SLUG"
  tmux set-option -t "$SLUG" remain-on-exit on 2>/dev/null || true
  # Auto-dismiss claude's startup "Settings Warning" prompt if it blocks launch.
  local i pane
  for i in $(seq 1 15); do
    sleep 1
    pane="$(tmux capture-pane -t "$SLUG" -p 2>/dev/null || true)"
    if grep -qiE 'Settings Warning|Enter to confirm' <<< "$pane"; then
      tmux send-keys -t "$SLUG" Enter
      sleep 1
      break
    fi
    # already past startup?
    grep -qiE 'remote-control|auto mode|esc to' <<< "$pane" && break
  done
  tmux set-option -t "$SLUG" remain-on-exit off 2>/dev/null || true
  # verify the pane is alive
  if ! tmux has-session -t "$SLUG" 2>/dev/null; then
    die "session '$SLUG' did not start"
  fi
  if [ "$(tmux list-panes -t "$SLUG" -F '#{pane_dead}' 2>/dev/null | head -1)" = "1" ]; then
    err "session command exited. Last output:"
    tmux capture-pane -t "$SLUG" -p 2>/dev/null | grep -v '^[[:space:]]*$' | tail -10 >&2
    die "spawn failed"
  fi
}
spawn_session

# ── report ──
echo
info "Done."
printf '  Mode:     %s\n' "$MODE"
printf '  Worktree: %s  (branch %s)\n' "$WT" "$BRANCH"
[ -n "$OLD_WT" ] && printf '  Renamed:  %s -> %s\n' "$OLD_WT" "$WT"
[ "$DRY" = 1 ] || printf '  Session:  tmux attach -t %s\n' "$SLUG"
