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

# Refuse ANY staged paths (including $SUB) — never overwrite an index entry
# this invocation did not create (Codex High: staged gitlink erase on no-op).
staged_any="$(git diff --cached --name-only)"
if [[ -n "$staged_any" ]]; then
  echo "sync-hextile-pipe: refuse — index already has staged paths:" >&2
  echo "$staged_any" >&2
  echo "commit or unstage them first" >&2
  exit 1
fi

# Parent gitlink SHA at HEAD
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

# Strict version read — never commit vunknown (Codex High)
read_version() {
  local f="$1"
  python3 - "$f" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
except FileNotFoundError:
    print(f"missing:{path}", file=sys.stderr)
    sys.exit(3)
except json.JSONDecodeError as e:
    print(f"malformed JSON {path}: {e}", file=sys.stderr)
    sys.exit(3)
ver = data.get("version")
if not isinstance(ver, str) or not ver.strip():
    print(f"missing or non-string version in {path}", file=sys.stderr)
    sys.exit(3)
print(ver.strip())
PY
}

claude_ver="$(read_version "$ROOT/$SUB/.claude-plugin/plugin.json")" || {
  echo "sync-hextile-pipe: refuse — cannot read Claude plugin version" >&2
  exit 1
}
codex_ver="$(read_version "$ROOT/$SUB/.codex-plugin/plugin.json")" || {
  echo "sync-hextile-pipe: refuse — cannot read Codex plugin version" >&2
  exit 1
}
if [[ "$claude_ver" != "$codex_ver" ]]; then
  echo "sync-hextile-pipe: WARN version lockstep broken claude=$claude_ver codex=$codex_ver" >&2
fi
ver="$claude_ver"

GROK_MARKET="$ROOT/.grok-plugin/marketplace.json"
python3 - "$GROK_MARKET" hextile-pipe \
  "https://github.com/ansonphong/hextile-pipe.git" "$new_sha" <<'PY'
import json, sys
path, name, url, sha = sys.argv[1:5]
with open(path, encoding="utf-8") as fh:
    data = json.load(fh)
for plugin in data.get("plugins", []):
    if plugin.get("name") == name:
        plugin["source"] = {"source": "url", "url": url, "sha": sha}
        break
else:
    sys.exit(f"plugin {name} missing from {path}")
with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY

# No-op when HEAD gitlink already matches worktree tip and Grok pin matches
if [[ -n "$old_sha" && "$old_sha" == "$new_sha" ]] \
  && git diff --quiet -- "$GROK_MARKET"; then
  echo "sync-hextile-pipe: already up to date at $short_sha (v$ver)"
  exit 0
fi

git add -- "$SUB" "$GROK_MARKET"

if git diff --cached --quiet -- "$SUB" "$GROK_MARKET"; then
  echo "sync-hextile-pipe: already up to date at $short_sha (v$ver)"
  exit 0
fi

msg="chore: pin hextile-pipe ${short_sha} (v${ver})"
git commit --only -m "$msg" -- "$SUB" "$GROK_MARKET"

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
