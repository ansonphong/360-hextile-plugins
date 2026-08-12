#!/usr/bin/env bash
# Advance plugins/hextile-pipe submodule pin to the tracked remote tip.
# Usage: ./scripts/sync-hextile-pipe.sh [--push]
# Safe: never git add -A; never stash/reset; no-op when already current.
set -euo pipefail

PUSH=0
for arg in "$@"; do
  case "$arg" in
    --push) PUSH=1 ;;
    -h|--help)
      echo "usage: $0 [--push]"
      echo "  Update plugins/hextile-pipe to remote tip and commit the pin if changed."
      echo "  --push  also git push origin (optional; fails if remote missing)"
      exit 0
      ;;
    *)
      echo "unknown arg: $arg (try --help)" >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$ROOT"

SUB="plugins/hextile-pipe"

if [[ ! -d "$ROOT/.git" ]]; then
  echo "sync-hextile-pipe: not a git repo: $ROOT" >&2
  exit 2
fi
if [[ ! -f "$ROOT/.gitmodules" ]]; then
  echo "sync-hextile-pipe: missing .gitmodules in $ROOT" >&2
  exit 2
fi
if [[ ! -e "$ROOT/$SUB" ]]; then
  echo "sync-hextile-pipe: missing submodule path $SUB" >&2
  exit 2
fi

# Refuse if parent has other staged paths (shared index safety)
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  if [[ "$line" != "$SUB" ]]; then
    echo "sync-hextile-pipe: refuse — other paths already staged:" >&2
    git diff --cached --name-only >&2
    echo "commit or unstage them first" >&2
    exit 1
  fi
done < <(git diff --cached --name-only)

# Parent gitlink SHA at HEAD (empty if uncommitted submodule)
old_sha="$(git ls-tree HEAD "$SUB" 2>/dev/null | awk '{print $3}' || true)"

# Submodule dirty check
if [[ -d "$ROOT/$SUB/.git" ]] || [[ -f "$ROOT/$SUB/.git" ]]; then
  if ! git -C "$ROOT/$SUB" diff --quiet 2>/dev/null \
     || ! git -C "$ROOT/$SUB" diff --cached --quiet 2>/dev/null; then
    echo "sync-hextile-pipe: refuse — dirty working tree in $SUB" >&2
    git -C "$ROOT/$SUB" status -sb >&2 || true
    exit 1
  fi
  untracked="$(git -C "$ROOT/$SUB" ls-files --others --exclude-standard | head -1 || true)"
  if [[ -n "$untracked" ]]; then
    echo "sync-hextile-pipe: refuse — untracked files in $SUB (e.g. $untracked)" >&2
    exit 1
  fi
fi

echo "sync-hextile-pipe: marketplace root $ROOT"
echo "sync-hextile-pipe: fetching submodule remote tip…"
git submodule update --init --remote -- "$SUB"

new_sha="$(git -C "$ROOT/$SUB" rev-parse HEAD)"
short_sha="$(git -C "$ROOT/$SUB" rev-parse --short HEAD)"

read_version() {
  local f="$1"
  if [[ -f "$f" ]]; then
    python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['version'])" "$f" 2>/dev/null || echo "unknown"
  else
    echo "missing"
  fi
}

claude_ver="$(read_version "$ROOT/$SUB/.claude-plugin/plugin.json")"
codex_ver="$(read_version "$ROOT/$SUB/.codex-plugin/plugin.json")"
if [[ "$claude_ver" != "$codex_ver" ]]; then
  echo "sync-hextile-pipe: WARN version lockstep broken claude=$claude_ver codex=$codex_ver" >&2
fi
ver="$claude_ver"

# Stage only the submodule gitlink
git add -- "$SUB"

head_link="${old_sha:-}"
# If HEAD already points at this SHA and index has no effective change, no-op
if git diff --cached --quiet -- "$SUB"; then
  # Nothing staged relative to HEAD for this path
  echo "sync-hextile-pipe: already up to date at $short_sha (v$ver)"
  exit 0
fi

# Double-check: staged gitlink mode 160000 object must equal new_sha
staged_sha="$(git ls-files -s -- "$SUB" | awk '{print $2}')"
if [[ -n "$head_link" && "$head_link" == "$new_sha" && "$staged_sha" == "$new_sha" ]]; then
  git restore --staged -- "$SUB" 2>/dev/null || git reset -q HEAD -- "$SUB" 2>/dev/null || true
  echo "sync-hextile-pipe: already up to date at $short_sha (v$ver)"
  exit 0
fi

msg="chore: pin hextile-pipe ${short_sha} (v${ver})"
git commit --only -m "$msg" -- "$SUB"

old_disp="${old_sha:-none}"
if [[ "$old_disp" != "none" && ${#old_disp} -ge 7 ]]; then
  old_disp="${old_disp:0:7}"
fi
echo "sync-hextile-pipe: committed pin $short_sha (v$ver)  [was $old_disp]"
echo "sync-hextile-pipe: $msg"

if [[ "$PUSH" -eq 1 ]]; then
  echo "sync-hextile-pipe: pushing…"
  git push origin HEAD
  echo "sync-hextile-pipe: push ok"
else
  echo "sync-hextile-pipe: pin local only (pass --push to push origin)"
fi

echo "sync-hextile-pipe: hosts still need marketplace update / reinstall hextile-pipe@360-hextile"
exit 0
