# VoxelRealms — Shared Agent & Engineering Instructions

> This file is the **single source of truth** for all AI coding agents (**Antigravity**, **Codex**, **Claude Code**) and human developers working in `VoxelRealms`.

## 1. Project Identity & Strategy
- **Codename:** `VoxelRealms`
- **Genre:** Dawnlands-inspired Voxel Survival Roleplay (1st & 3rd person).
- **Phase 1 Platform:** Roblox (`Luau` + `Rojo` + `Wally`).
- **Phase 2 Platform (Future):** Standalone PC game (`Unity` + `C#`).
- **IP Protection Rule:** Never import third-party Roblox Toolbox models or unlicensed assets. All 3D voxel models, rigs, animations, and textures must be original assets stored under `assets/` so they transfer cleanly to the future standalone PC version.

---

## 2. Non-Negotiable Architecture Rules
1. **File-System First (Rojo):** All game code lives in `src/`. Never tell developers to paste logic into `.rbxl` scripts outside Rojo.
2. **Strict Luau Everywhere:** Every `.luau` file MUST begin with `--!strict`. Avoid `any` unless strictly required at an untyped Roblox API boundary (and document why).
3. **Domain Isolation (Multi-Dev Scaling):**
   - Server features live in `src/server/Services/<DomainName>Service/init.luau`.
   - Client features live in `src/client/Controllers/<DomainName>Controller/init.luau`.
   - Keep each Service/Controller self-contained so multiple developers and AI agents can work on different domains in parallel without merge conflicts.
4. **Lifecycle Contract (`Init` → `Start`):**
   - Every Service and Controller exports `Init()` (wire up internal state/remotes, do NOT yield or call other services' runtime methods) and `Start()` (connect events, start loops, interact with other services).
   - Bootstrappers (`src/server/init.server.luau` and `src/client/init.client.luau`) load modules deterministically: all `Init()` calls complete before any `Start()` call begins.
5. **Data-Driven Configuration:**
   - Never hardcode role perks, item stats, crafting recipes, voxel block definitions, or biome parameters inside Service/Controller logic.
   - Define them in `src/shared/Config/` with strict types from `src/shared/Types/`.
6. **Server-Authoritative Security:**
   - The client only sends *intent* (e.g., "I want to place block X at grid cell Y", "I want to select Role Z").
   - The server MUST validate permissions, distances, cooldowns, stamina, inventory items, and grid rules before mutating state.
7. **Single Network Registry:**
   - All `RemoteEvent` and `RemoteFunction` names and payload types MUST be declared in `src/shared/Network/Remotes.luau` and `src/shared/Types/`. Never scatter ad-hoc `Instance.new("RemoteEvent")` calls across services.

---

## 3. Coding Style & Quality Gates
- Follow [`stylua.toml`](stylua.toml) (Tabs, 120-char width, double quotes, explicit call parentheses).
- Follow [`selene.toml`](selene.toml) (no implicit globals, no unused variables, no shadowing).
- Naming conventions:
  - Modules, Services, Controllers, Types: `PascalCase`
  - Functions, local variables, table keys: `camelCase`
  - Module-level constants: `UPPER_SNAKE_CASE`
  - Private module functions/fields: prefix with `_` (e.g., `_validatePlacement`)
- Clean up all connections and instances using `Trove` (once Wally packages are installed) or explicit cleanup functions on `PlayerRemoving` / `CharacterRemoving`.
- Before finishing any coding task, run (when installed):
  - `stylua --check src`
  - `selene src`

---

## 4. Mandatory Documentation Discipline
**Documentation is never an afterthought.** Whenever you add or modify systems:
1. New or changed Service, Controller, or Remote → update [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).
2. New or changed game mechanic, Role, or item/building rule → update [`docs/GDD.md`](docs/GDD.md).
3. New Blender model, rig, or export convention → update [`docs/ASSET_PIPELINE.md`](docs/ASSET_PIPELINE.md).
4. Every completed feature or milestone → add an entry under `[Unreleased]` in [`docs/CHANGELOG.md`](docs/CHANGELOG.md).

---

## 5. Multi-Agent & Multi-Developer Coordination
- Work on one focused feature branch per task (`feat/<domain>`, `fix/<issue>`, `art/<asset>`, `docs/<topic>`).
- Keep PRs small and scoped to one domain whenever possible.
- If a task requires changing a shared contract (`src/shared/Types/` or `src/shared/Network/`), update and document the contract first so other devs/agents can safely code against it in parallel.
