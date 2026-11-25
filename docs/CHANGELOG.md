# Changelog

All notable changes to **VoxelRealms** are documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- **Sprint 2 — Survival Gathering, Inventory & Crafting (`feat/survival-gathering`):**
  - Added data-driven configs for survival items (`Config/Items.luau`), crafting recipes including Role-exclusive blueprints (`Config/Recipes.luau`), and voxel resource nodes (`Config/ResourceNodes.luau`).
  - Implemented `WorldService` spawning voxel-built pine trees, stone boulders, iron ore veins, and berry/herb bushes with Role perk bonuses (Blacksmith mining speed, Alchemist forage yield) and respawn timers.
  - Implemented `InventoryService` (starter survival pack, authoritative crafting, consumable usage wired to `SurvivalService.ModifyStats`).
  - Added `GatherController` (`[E]` gather prompt + highlight) and upgraded `UIController` with `[I]` Inventory, `[C]` Crafting Bench, and top-center Toast Notifications.
- **Sprint 1 Core Feel (`feat/sprint1-core-feel`):**
  - Fixed `CameraController` 1st-to-3rd-person toggle (`V` key) by keeping `CameraMode.Classic` and snapping zoom bounds across render steps before restoring scroll zoom.
  - Client voxel building (`BuildController`) with mouse raycasting, translucent 4×4×4 ghost preview, reach tinting, `[B]` build mode toggle, `[1-5]` hotbar block selection, and Left/Right-click place & remove.
  - Player character overlap validation in `VoxelBuildService` to prevent trapping players inside placed voxels.
  - Authoritative stamina/hunger simulation, sprint speed + role perk multipliers, and dodge validation in `SurvivalService`.
  - Dawnlands-style sprint (`LeftShift`) and directional dodge dash (`Q`) in `MovementController`.
  - Procedural Survival/Role/Hotbar HUD (`UIController`) with live Health/Stamina/Hunger bars, `[R]` 4-role selector modal, voxel hotbar, and toggleable `[H]` controls panel.
- Tracked `places/main.rbxl` baseplate shell in Git LFS and added local `roblox.yml` Selene standard library.
- Initialized `VoxelRealms` multi-developer Git + Git LFS repository.
- Configured Roblox toolchain (`rokit.toml`, `default.project.json`, `wally.toml`, `stylua.toml`, `selene.toml`) and GitHub Actions CI (`ci.yml`).
- Added shared AI agent instructions (`AGENTS.md`, `CLAUDE.md`) for Antigravity, Codex, and Claude Code.
- Added living documentation (`docs/GDD.md`, `docs/ARCHITECTURE.md`, `docs/ASSET_PIPELINE.md`, `docs/CONTRIBUTING.md`).
- Scaffolded modular Luau architecture (`src/shared`, `src/server/Services`, `src/client/Controllers`) with strict typing (`--!strict`), deterministic `Init`/`Start` bootstrappers, starter Role/Block configs, and VoxelGrid math utilities.
