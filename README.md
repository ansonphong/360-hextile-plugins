# 360 Hextile — agent marketplace

Catalog of agent plugins for **360 artists and studio workflows**.

| Field | Value |
|-------|--------|
| **Display** | 360 Hextile |
| **Tech marketplace name** | `360-hextile` |
| **GitHub** | [`ansonphong/360-hextile-plugins`](https://github.com/ansonphong/360-hextile-plugins) |
| **Local catalog** | `D:\Projects\360-HEXTILE\360-hextile-plugins` |

This repo is **marketplace-only**. Product code lives in each plugin’s own repo (git submodules under `plugins/`).

## Plugins

| Plugin | Job | Product repo | Install id |
|--------|-----|--------------|------------|
| **hextile-pipe** | Studio matte / Adobe helpers | `D:\Projects\360-HEXTILE\hextile-pipe` (GitHub: `ansonphong/hextile-pipe`) | `hextile-pipe@360-hextile` |
| **hextile-agent** | App workflow automation — MCP tools + skill over localhost HTTP | `D:\Projects\360-HEXTILE\hextile-agent` (GitHub: `ansonphong/360-hextile-agent`) | `hextile-agent@360-hextile` |

`hextile-agent` is the plugin. Do not call it `hextile`.

## Install

Add the catalog once, then install either plugin (or both).

```bash
# Claude Code
/plugin marketplace add ansonphong/360-hextile-plugins
/plugin install hextile-pipe@360-hextile
/plugin install hextile-agent@360-hextile

# Grok
grok plugin marketplace add ansonphong/360-hextile-plugins
grok plugin install hextile-pipe --trust
grok plugin install hextile-agent --trust

# Codex
codex plugin marketplace add D:\Projects\360-HEXTILE\360-hextile-plugins
codex plugin add hextile-pipe@360-hextile
codex plugin add hextile-agent@360-hextile

# Studio local path
grok plugin marketplace add D:\Projects\360-HEXTILE\360-hextile-plugins
```

After install:

```text
/hextile-pipe doctor
/hextile-knockout path/to/file.png
```

## Layout

```text
D:\Projects\360-HEXTILE\
  360-hextile-plugins/               # this catalog
    .claude-plugin/marketplace.json  # name: 360-hextile
    .agents/plugins/marketplace.json # name: 360-hextile
    .grok-plugin/marketplace.json    # name: 360-hextile
    plugins/
      hextile-pipe/                  # submodule → ansonphong/hextile-pipe
      hextile-agent/                 # submodule → ansonphong/360-hextile-agent
  hextile-pipe/                      # product repo
  hextile-agent/                     # product repo
```

**Hard rule:** all three marketplace JSON `"name"` fields stay **`360-hextile`** (Codex freezes upgrades on name drift).

If a host rejects a leading-digit marketplace id, rename tech id to **`hextile-360`** in all three indexes (same tokens). Do not use a bare `hextile` marketplace or plugin id.

## Refresh a plugin (keep submodule pins in sync)

Ship in a plugin repo, then advance this catalog’s pin:

```bash
# one command per plugin — fetches remote tip, commits the pin only if the SHA changed
./scripts/sync-hextile-pipe.sh     # ansonphong/hextile-pipe          → plugins/hextile-pipe
./scripts/sync-hextile-agent.sh    # ansonphong/360-hextile-agent     → plugins/hextile-agent
# optional: append --push to either   # when origin exists

# first-time / clone hygiene
git submodule update --init --recursive
```

Already current → exit 0 and prints `already up to date` with short SHA + version.

**Hosts do not auto-update.** After the pin moves, refresh install caches:

| Host | After pin moves |
|------|-----------------|
| Claude | marketplace update `360-hextile`, then reinstall (`hextile-pipe@360-hextile` / `hextile-agent@360-hextile`) |
| Grok | `grok plugin marketplace update` and/or reinstall the plugin |
| Codex | `codex plugin marketplace upgrade 360-hextile` (then re-add plugin if needed) |

Manual equivalent (if you skip the script):

1. Bump plugin.json versions lockstep in the product repo and push.
2. `git submodule update --remote plugins/hextile-pipe` or `plugins/hextile-agent`
3. Commit the gitlink only: `git add plugins/<name> && git commit --only -m "…" -- plugins/<name>`

## License

Private / studio catalog unless you add a LICENSE.
