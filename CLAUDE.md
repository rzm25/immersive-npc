# CLAUDE.md

Auto-loaded by Claude Code. This module is part of the `/workspaces/sandyb` AzerothCore workspace;
the workspace-root `CLAUDE.md` (environment, sibling modules, shared knowledge base) is merged in
automatically.

**Kickoff instructions and this module's filled-in Project Context live in `agent.md` — read it
first.** The shared cross-project truth (schema, gotchas, ID ranges) lives in
`/workspaces/sandyb/source` and must be read before writing C++ or SQL, and updated when you learn
something new.

@agent.md
@TRUTH_SOURCES.md
@docs/PROJECT_PLAN.md
@agent-notes/immersive-npc-session-notes.md

<!-- NOTE: this is a Lua module for ALE (azerothcore/mod-ale) — no C++ build, no loader
     symbol. Deployment = copy scripts/inc/ into ALE.ScriptPath (lua_scripts); reload with
     `.reload ale`. The engine pin + verified event IDs/methods are in docs/SOURCES.md; read
     it before touching event registration (a wrong event id fails SILENTLY in Lua). -->
<!-- The @-imports above pull these files into context automatically when they exist. -->
