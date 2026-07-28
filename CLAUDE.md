# hami-habibi

Game design documentation for an asymmetric multiplayer chase game ("Catch Me If You
Can" style: **Runners** evade, **Hunters** pursue). This repo holds **prose design docs
only** — there is no application code, build system, package manager, test suite, or
linter. Changes are reviewed by reading them.

## Layout

```
docs/maps/UrbanJungle.md   The only content file: Urban Jungle map design (Vice City / 80s Miami theme)
CLAUDE.md                  This file
.claude/                   Claude Code configuration: skills, hooks, statusline
.mcp.json                  MCP servers (higgsfield, HTTP — requires interactive OAuth)
```

## The design docs

`docs/maps/UrbanJungle.md` is the template for any future map doc. Follow its five-section
structure when adding or editing maps:

1. **Overall Theme and Atmosphere** — aesthetic, lighting, soundscape, verticality, feeling
2. **Key Areas and Landmarks** — one `###` subsection per district, each with a
   `**Description:**` bullet and a `**Gameplay:**` bullet list
3. **Interactive Elements and Environmental Hazards** — each entry states
   **Interaction** / **Effect** / **Use**
4. **Character Ability Interactions** — Runner abilities, then Hunter abilities; each ability
   gets its per-district usage notes
5. **Visual References and Inspirations** — games, film, architecture, music

Established game vocabulary (keep it consistent across docs):

- **Runners** — abilities: Quick Dash, Decoy, Stealth Cloak
- **Hunters** — abilities: Grappling Hook, Tracker Drone, Net Trap
- Districts in Urban Jungle: Ocean Drive Promenade, Neon Strip, The Vice Marina,
  Downtown Business District, Little Havana/Industrial Mix

Every gameplay element should say what it means for *both* sides — the docs consistently
frame each feature as an advantage/limitation for Runners and for Hunters. Keep that
balance when adding content.

Known issue: `docs/maps/UrbanJungle.md:19` contains a stray non-English word
(`ощущений`) mid-sentence. Fix it if you touch that paragraph.

## Workflow

- **Branches**: feature branches, kebab-case, descriptive prefix —
  e.g. `feature/vice-city-map-design`. Never commit directly to a shared branch you
  weren't asked to use.
- **Commits**: short imperative subject describing the design change
  (e.g. "Draft initial map design for Urban Jungle (Vice City theme)").
- **Verification**: there is nothing to run. Verify by re-reading the diff for structural
  consistency with the section format above and for vocabulary consistency.
- **Push**: `git push -u origin <branch-name>`. Don't open a PR unless asked.

## Claude Code tooling (`.claude/`)

Configuration lives in `.claude/settings.json` and is checked in, so edits affect everyone.

- **Skills** (`.claude/skills/`) — installed skill packages, each with a `SKILL.md`:
  - `ponytail` + `ponytail-review` / `-audit` / `-debt` / `-gain` / `-help` — enforces
    minimal, lazy solutions. Activated automatically at session start by a hook.
  - `graphify` — turns a folder into a knowledge graph (`/graphify`).
  - `impeccable` — frontend/UI design workflows (large Node script tree under `scripts/`).
  - `obsidian-markdown`, `obsidian-bases`, `obsidian-cli`, `json-canvas` — Obsidian vault
    and canvas authoring.
  - `defuddle` — clean markdown extraction from web pages; prefer over raw fetching.
- **Hooks** (`.claude/settings.json`):
  - `SessionStart` / `SubagentStart` / `UserPromptSubmit` run the ponytail Node hooks —
    these work.
  - `PreToolUse` on `Bash|Grep` and `Read|Glob` call `/root/.local/bin/graphify hook-guard`.
    **The `graphify` binary is not installed in this environment**, so these are currently
    no-ops. Don't assume graph-backed search is available.
- **Statusline** (`.claude/statusline.sh`) — prints `<dir> (<branch>) [PONYTAIL]`; requires
  `python3` and `git`.
- **MCP** (`.mcp.json`) — `higgsfield` over HTTP. It needs OAuth, which can't be completed
  in a non-interactive session; report it as unavailable rather than working around it.

## Graphify

There is **no** `graphify-out/` directory in this repo and no graphify CLI installed. If a
knowledge graph is ever generated (`graphify .`), prefer `graphify query "<question>"`,
`graphify path "<A>" "<B>"`, and `graphify explain "<concept>"` over raw grep, and run
`graphify update .` after changes. Until then, read `docs/` directly — the repo is small
enough that reading the one map doc end to end is the fastest path.
