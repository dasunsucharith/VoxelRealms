# VoxelRealms

A **Dawnlands-inspired Voxel Survival Roleplay** game built first for **Roblox (Luau + Rojo)** to validate gameplay and build a community, with an engine-agnostic **Blender voxel asset pipeline** ready for a future standalone **PC (Unity + C#)** release.

## Core Pillars
- **Survival Crafting & Exploration:** Gather resources, manage Health/Stamina/Hunger, craft gear, and survive varied biomes and creatures.
- **Meaningful Roleplay Roles:** Every player chooses a Role (e.g., Architect, Blacksmith, Hunter, Alchemist) with unique perks, recipes, and co-op synergy.
- **Voxel World & Building:** Grid-snapped voxel building (`1 block = 4×4×4 studs`) paired with custom voxel-art 3D characters, weapons, and props built in Blender.
- **1st & 3rd Person Gameplay:** Seamless switching between 3rd-person action-survival and 1st-person building/combat.
- **Multi-Dev & Multi-AI Ready:** 100% file-system-first Luau codebase synced via Rojo, with strict domain isolation and shared rules for human devs and AI coding agents (**Antigravity, Codex, Claude Code**).

---

## Quickstart for Developers

### 1. Prerequisites
- [Git](https://git-scm.com/) + [Git LFS](https://git-lfs.com/)
- [Rokit](https://github.com/rojo-rbx/rokit) (manages exact versions of Rojo, Wally, StyLua, and Selene)
- [Roblox Studio](https://create.roblox.com/) + the **Rojo Studio Plugin**
- [Blender](https://www.blender.org/) (for 3D voxel asset work)

### 2. First-Time Setup
```powershell
git clone <your-repo-url> VoxelRealms
cd VoxelRealms
git lfs pull
rokit install
wally install
```

### 3. Run Locally with Roblox Studio
```powershell
rojo serve
```
Then open `places/main.rbxl` (or a new Baseplate saved to `places/main.rbxl`) in Roblox Studio, click **Plugins → Rojo → Connect**, and hit **Play (F5)**.

### 4. Before Opening a Pull Request
```powershell
stylua --check src
selene src
```

---

## Repository Layout
- [`AGENTS.md`](AGENTS.md) / [`CLAUDE.md`](CLAUDE.md) — Shared rules for Antigravity, Codex, and Claude Code.
- [`docs/GDD.md`](docs/GDD.md) — Game Design Document (mechanics, roles, roadmap).
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — System boundaries, networking, and folder ownership.
- [`docs/ASSET_PIPELINE.md`](docs/ASSET_PIPELINE.md) — Blender voxel scale, palette, rigging, and export rules.
- [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) — Branching, PR rules, and team workflow.
- [`docs/CHANGELOG.md`](docs/CHANGELOG.md) — Ongoing change log.
- `src/shared/` — Data configs (`Config/`), strict types (`Types/`), remotes (`Network/`), pure utilities (`Util/`).
- `src/server/` — Authoritative server Services (`Services/`).
- `src/client/` — Local player Controllers (`Controllers/`).
- `assets/` — 100% owned Blender source files, FBX/GLB exports, textures, and audio.
- `places/` — Thin Roblox Studio place shell (`main.rbxl`) for map/lighting only (no scripts!).
