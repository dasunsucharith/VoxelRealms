# Changelog

All notable changes to **VoxelRealms** are documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- **Sprint 3 — Action Combat, Voxel Creatures & Creature Models (`feat/combat-creatures`):**
  - Added creature configs (`Config/Creatures.luau`), monster loot items (`raw_meat`, `wolf_pelt`, `slime_gel`, `roast_meat`), and the Hunter-exclusive `hunter_trail_feast` recipe.
  - Implemented `CreatureService` (patrolling Voxel Forest Slimes and Voxel Timber Wolves with safe-shrine respect, aggro/chase/attack AI, HP billboards, hit flash, knockback, loot drops, and respawning).
  - Implemented `CombatService` + `CombatController` (`[F]` or Build-OFF Left-Click melee strikes, stamina cost, Hunter/Blacksmith +25% melee bonus, voxel slash VFX, and floating damage numbers).
  - Built and exported original Blender voxel creature models (`vr_mob_wolf` rigged with `Wolf_Idle` & `Wolf_Run`, and `vr_mob_slime`) tracked in Git LFS via `tools/blender/build_voxel_creatures.py`.
- **Sprint 3 — World Atmosphere, Campfires & Starter Ruins (`feat/world-atmosphere`):**
  - Implemented `AtmosphereService` with a Dawnlands-inspired 24-hour Day/Night cycle (`Dawn`, `Day`, `Dusk`, `Night`), `Atmosphere` + `BloomEffect` lighting, and glowing placeable Voxel Campfires with flickering warm light, embers, and passive Health/Stamina/Hunger regeneration aura.
  - Upgraded `campfire_kit` to a real placeable item in `InventoryService` and `UIController` (`PLACE` button).
  - Added lush meadow ground styling, a Voxel Ancient Ruin Shrine with glowing rune crystal, cobblestone stepping path, and a starter lit campfire in `WorldService`, plus a live Day/Clock pill in `UIController`.
- **Sprint 2 — Cloud Data Persistence (`feat/data-persistence`):**
  - Implemented `DataService` (`VoxelRealms_PlayerData_v1`) with strict `PlayerProfile` schema reconciliation, `UpdateAsync` retry backoff, 120s dirty-flag autosave, `BindToClose` flush, and graceful offline Studio session fallback.
  - Wired `RoleService`, `InventoryService`, and `SurvivalService` to load and persist player roles, inventories, health, and hunger across sessions.
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
