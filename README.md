# 🌐 360 Hextile — agent marketplace

Agent tools for **360 artists**. Add the catalog once. Install a plugin. Start working.

| | |
|:--|:--|
| **Marketplace** | `360-hextile` |
| **GitHub** | [ansonphong/360-hextile-plugins](https://github.com/ansonphong/360-hextile-plugins) |
| **On disk** | `D:\Projects\360-HEXTILE\360-hextile-plugins` |

This repo is the **catalog**. Product code lives in each plugin’s own repo.

---

## Install

Sixty seconds. Pick your host.

<details open>
<summary><strong>Claude Code</strong></summary>

```text
/plugin marketplace add ansonphong/360-hextile-plugins
/plugin install hextile-pipe@360-hextile
/plugin install hextile@360-hextile
```

Then:

```text
/hextile-pipe doctor
```

</details>

<details open>
<summary><strong>Codex</strong></summary>

```text
codex plugin marketplace add D:\Projects\360-HEXTILE\360-hextile-plugins
codex plugin add hextile-pipe@360-hextile
codex plugin add hextile@360-hextile
```

</details>

<details>
<summary><strong>Grok</strong></summary>

```text
grok plugin marketplace add ansonphong/360-hextile-plugins
grok plugin install hextile-pipe --trust
grok plugin install hextile --trust
```

Studio path if you already have the catalog cloned:

```text
grok plugin marketplace add D:\Projects\360-HEXTILE\360-hextile-plugins
```

</details>

---

## Plugins

| Plugin | What it is | You type |
|:-------|:-----------|:---------|
| **hextile-pipe** | Studio matte and Adobe helpers. Whiten, cutout, knockout, despeckle, trim. | `hextile-pipe@360-hextile` |
| **hextile-agent** | Drive the 360 Hextile app from the agent. Workflows, renders, 360-LoRA, over localhost HTTP. | `hextile@360-hextile` |

**hextile-agent** is the app plugin. The catalog id is still `hextile` so the install command stays `hextile@360-hextile`.

| Plugin | Lives here |
|:-------|:-----------|
| hextile-pipe | `D:\Projects\360-HEXTILE\hextile-pipe` · [ansonphong/hextile-pipe](https://github.com/ansonphong/hextile-pipe) |
| hextile-agent | `D:\Projects\360-HEXTILE\hextile-agent` · [ansonphong/360-hextile-agent](https://github.com/ansonphong/360-hextile-agent) |

---

## After install

```text
/hextile-pipe doctor
/hextile-knockout path/to/file.png
```

App plugin talks to a local 360 Hextile instance. Open the app first if a command cannot reach it.

---

## Layout

```text
D:\Projects\360-HEXTILE\
  360-hextile-plugins/                 this catalog
    .claude-plugin/marketplace.json    name: 360-hextile
    .agents/plugins/marketplace.json   name: 360-hextile
    .grok-plugin/marketplace.json      name: 360-hextile
    plugins/
      hextile-pipe/                    → ansonphong/hextile-pipe
      hextile/                         → ansonphong/360-hextile-agent   (hextile-agent)
  hextile-pipe/                        product repo
  hextile-agent/                       product repo
```

All three marketplace JSON `"name"` fields stay **`360-hextile`**. Codex freezes upgrades if that name drifts.

If a host rejects a leading-digit marketplace id, rename the tech id to **`hextile-360`** in all three indexes. Same tokens everywhere. Do not use a bare `hextile` marketplace name.

---

## Refresh a plugin

Ship in the product repo, then move this catalog’s pin.

```bash
./scripts/sync-hextile-pipe.sh     # ansonphong/hextile-pipe        → plugins/hextile-pipe
./scripts/sync-hextile.sh          # ansonphong/360-hextile-agent   → plugins/hextile
# append --push when origin should move too

git submodule update --init --recursive
```

Already current: exit 0, prints `already up to date` with short SHA + version.

Hosts do **not** auto-update. After the pin moves:

| Host | Then |
|:-----|:-----|
| Claude | marketplace update `360-hextile`, reinstall the plugin |
| Grok | `grok plugin marketplace update` and/or reinstall |
| Codex | `codex plugin marketplace upgrade 360-hextile` |

Manual path:

1. Bump `plugin.json` in the product repo and push.
2. `git submodule update --remote plugins/hextile-pipe` or `plugins/hextile`
3. Commit the gitlink only.

---

Private studio catalog unless you add a LICENSE.
