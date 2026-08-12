# 360 Hextile — agent marketplace

Catalog of agent plugins for **360 artists and studio workflows**.

| Field | Value |
|-------|--------|
| **Display** | 360 Hextile |
| **Tech marketplace name** | `360-hextile` |
| **GitHub** | [`ansonphong/360-hextile-plugins`](https://github.com/ansonphong/360-hextile-plugins) |

This repo is **marketplace-only**. Product code lives in each plugin’s own repo (git submodules under `plugins/`).

## Audience split (do not blur)

| Marketplace | Audience | Example install |
|-------------|----------|-----------------|
| **meta-dev** | Developers | `meta-dev@meta-dev` |
| **chapterwise-plugins** | Writers | chapterwise plugins |
| **360-hextile** | 360 artists / studio | `hextile-pipe@360-hextile` |

## Plugins

| Plugin | Job | Install id |
|--------|-----|------------|
| **hextile-pipe** | Studio matte / Adobe helpers | `hextile-pipe@360-hextile` |
| **hextile** (future) | APP pipeline automation | `hextile@360-hextile` |

## Install

```bash
# Claude Code
/plugin marketplace add ansonphong/360-hextile-plugins
/plugin install hextile-pipe@360-hextile

# Grok
grok plugin marketplace add ansonphong/360-hextile-plugins
grok plugin install hextile-pipe --trust

# Codex
codex plugin marketplace add <path-to-360-hextile-plugins>
codex plugin add hextile-pipe@360-hextile

# Studio local path
grok plugin marketplace add /path/to/360-hextile-plugins
```

After install:

```text
/hextile-pipe doctor
/hextile-knockout path/to/file.png
```

## Layout

```text
360-hextile-plugins/
  .claude-plugin/marketplace.json    # name: 360-hextile
  .agents/plugins/marketplace.json   # name: 360-hextile
  .grok-plugin/marketplace.json      # name: 360-hextile
  plugins/
    hextile-pipe/                    # submodule → ansonphong/hextile-pipe
```

**Hard rule:** all three marketplace JSON `"name"` fields stay **`360-hextile`** (Codex freezes upgrades on name drift).

If a host rejects a leading-digit marketplace id, rename tech id to **`hextile-360`** in all three indexes (same tokens) — not bare `hextile`.

## Refresh a plugin

1. Ship a new version in the plugin repo (bump both plugin.json files lockstep).
2. Here: `git submodule update --remote plugins/hextile-pipe` (or pin a SHA).
3. Commit the submodule pin.
4. On the host: marketplace update / reinstall `hextile-pipe@360-hextile`.

```bash
git submodule update --init --recursive
```

## License

Private / studio catalog unless you add a LICENSE.
