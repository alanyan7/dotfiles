#!/usr/bin/env bash
# Corner-case tests for worktree-session against a throwaway repo.
set -uo pipefail
# Resolve the script relative to this test file (portable), allow override.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT="${SCRIPT:-$HERE/../skills/worktree-sessions/worktree-session.sh}"
T=$(mktemp -d /tmp/wtt.XXXXXX)
export WORKTREE_BASE="$T/wts"
export WORKTREE_USER="tester"
# stub session command that ignores the appended slug arg and stays alive
printf '#!/usr/bin/env bash\nexec sleep 120\n' > "$T/fakeclaude"
chmod +x "$T/fakeclaude"
export WORKTREE_SESSION_CMD="$T/fakeclaude"
REMOTE="$T/remote.git"
REPO="$T/repo"
export WORKTREE_REPO="$REPO"

pass=0; fail=0
ok()  { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

# tmux sessions created here, tracked for cleanup
SESSIONS=()
track() { SESSIONS+=("$1"); }
cleanup() {
  for s in "${SESSIONS[@]:-}"; do tmux kill-session -t "$s" 2>/dev/null; done
  rm -rf "$T"
}
trap cleanup EXIT

# ── set up bare remote + working repo ──
git init -q --bare "$REMOTE"
git init -q "$REPO"
git -C "$REPO" config user.email t@t.com; git -C "$REPO" config user.name tester
echo hi > "$REPO/a.txt"; git -C "$REPO" add .; git -C "$REPO" commit -qm init
git -C "$REPO" branch -m main
git -C "$REPO" remote add origin "$REMOTE"
git -C "$REPO" push -q -u origin main
# a pre-existing local branch with no worktree
git -C "$REPO" branch tester/preexist main
# a remote-only branch
git -C "$REPO" branch tmp-remote main
git -C "$REPO" push -q origin tmp-remote:tester/remoteonly
git -C "$REPO" branch -D tmp-remote >/dev/null

echo "== T1: create new slug =="
$SCRIPT feature-a >/dev/null 2>&1; track feature-a
ok "branch tester/feature-a created" 'git -C "$REPO" show-ref --verify --quiet refs/heads/tester/feature-a'
ok "worktree dir exists"             'test -d "$WORKTREE_BASE/feature-a"'
ok "tmux session feature-a running"  'tmux has-session -t feature-a 2>/dev/null'

echo "== T2: idempotent re-run while session exists =="
out=$($SCRIPT feature-a 2>&1); rc=$?
ok "reports already exists, exit 0"  '[ $rc -eq 0 ] && printf "%s" "$out" | grep -qi "already exists"'

echo "== T3: worktree exists but session gone -> respawn =="
tmux kill-session -t feature-a 2>/dev/null
$SCRIPT feature-a >/dev/null 2>&1
ok "session respawned"               'tmux has-session -t feature-a 2>/dev/null'
ok "no duplicate worktree"           '[ $(git -C "$REPO" worktree list | grep -c feature-a) -eq 1 ]'

echo "== T4: existing LOCAL branch (with slash) -> worktree+session =="
$SCRIPT tester/preexist >/dev/null 2>&1; track preexist
ok "slug=preexist worktree exists"   'test -d "$WORKTREE_BASE/preexist"'
ok "checked out tester/preexist"     '[ "$(git -C "$WORKTREE_BASE/preexist" rev-parse --abbrev-ref HEAD)" = "tester/preexist" ]'
ok "session preexist running"        'tmux has-session -t preexist 2>/dev/null'

echo "== T5: remote-only branch -> tracking worktree =="
$SCRIPT tester/remoteonly >/dev/null 2>&1; track remoteonly
ok "remoteonly worktree exists"      'test -d "$WORKTREE_BASE/remoteonly"'
ok "tracks origin"                   'git -C "$WORKTREE_BASE/remoteonly" rev-parse --abbrev-ref @{upstream} | grep -q origin/tester/remoteonly'

echo "== T6: attach by path =="
tmux kill-session -t preexist 2>/dev/null
$SCRIPT "$WORKTREE_BASE/preexist" >/dev/null 2>&1
ok "attach respawned session"        'tmux has-session -t preexist 2>/dev/null'

echo "== T7: legacy <USER>- prefixed dir attach -> rename =="
git -C "$REPO" worktree add -q "$WORKTREE_BASE/tester-legacy" -b tester/legacy main
$SCRIPT "$WORKTREE_BASE/tester-legacy" >/dev/null 2>&1; track legacy
ok "renamed to base/legacy"          'test -d "$WORKTREE_BASE/legacy" && ! test -d "$WORKTREE_BASE/tester-legacy"'
ok "session legacy running"          'tmux has-session -t legacy 2>/dev/null'

echo "== T8: invalid slug rejected =="
$SCRIPT "Bad_Slug" >/dev/null 2>&1; rc=$?
ok "invalid slug -> nonzero exit"    '[ $rc -ne 0 ]'
$SCRIPT "no-such-thing/nope" >/dev/null 2>&1; rc=$?
ok "unknown branch/path -> nonzero"  '[ $rc -ne 0 ]'

echo "== T9: --no-session =="
$SCRIPT --no-session quiet-one >/dev/null 2>&1
ok "worktree created"                'test -d "$WORKTREE_BASE/quiet-one"'
ok "no tmux session"                 '! tmux has-session -t quiet-one 2>/dev/null'

echo "== T10: --dry-run makes no changes =="
$SCRIPT --dry-run never-made >/dev/null 2>&1
ok "no worktree created"             '! test -d "$WORKTREE_BASE/never-made"'
ok "no branch created"               '! git -C "$REPO" show-ref --verify --quiet refs/heads/tester/never-made'

echo "== T11: --push pushes a new local branch =="
$SCRIPT --no-session --push pushme >/dev/null 2>&1
ok "pushme on origin"                '[ -n "$(git -C "$REPO" ls-remote --heads origin tester/pushme)" ]'

echo
echo "RESULTS: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
