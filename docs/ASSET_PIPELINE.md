# VoxelRealms — Blender Voxel Asset Pipeline

> **Goal:** Every 3D model, rig, animation, and texture built in Blender must work cleanly in **Roblox Studio today** AND transfer directly to **Unity (Standalone PC)** in Phase 2 with zero rework.

---

## 1. Golden Scale & Orientation Rules
- **Blender Unit Scale:** Metric, **`1 Blender meter = 1 Voxel Block`**.
  - A standard voxel block is `1.0m × 1.0m × 1.0m`.
  - A standard playable voxel humanoid is **`~1.8m` tall** (roughly `1.8` blocks tall).
- **Roblox Mapping:** `1 Blender meter = 4 Roblox studs` (apply uniform scale on import or export via our Blender export preset).
- **Future Unity Mapping:** `1 Blender meter = 1 Unity unit` natively.
- **Forward & Up Axes:** Model facing **`-Y` forward** (Blender standard), **`+Z` up**, with origin placed at the **bottom center (`0, 0, 0`)** for characters/props/trees and **center or bottom-grid corner** consistently for voxel blocks.
- **Apply Transforms:** Always apply Rotation & Scale (`Ctrl + A`) before exporting.

---

## 2. Visual & Performance Standards
- **Shared Color Palette Texture:**
  - Store the master voxel palette in `assets/textures/voxel_palette_v1.png` (e.g., `16×16` or `32×32` nearest-neighbor / crisp pixels).
  - Map solid voxel faces to single palette swatches so models share one material and draw-call batch cleanly in both Roblox and Unity.
- **Triangle Budgets (Guidelines):**
  - Simple voxel prop / tool: `< 300` tris
  - Modular building piece / workbench: `< 800` tris
  - Playable voxel character / creature: `800 – 2,500` tris
- **Zero Unlicensed Assets:** Never import free Roblox Toolbox models. All assets in `assets/` are 100% original IP owned by the team.

---

## 3. Folder Organization & Naming Conventions
```text
assets/
├── blender/
│   ├── characters/   # vr_char_base_rig.blend, vr_char_blacksmith.blend
│   ├── creatures/    # vr_mob_wolf.blend
│   ├── tools/        # vr_tool_axe_wood.blend, vr_tool_pickaxe_stone.blend
│   ├── props/        # vr_prop_campfire.blend, vr_prop_anvil.blend
│   └── environment/  # vr_env_pine_tree.blend, vr_env_ruin_pillar.blend
├── exports/          # Matching subfolders with .fbx (Roblox/Unity) & .glb
├── textures/         # Shared palettes & 2D UI icons (.png)
└── audio/            # .wav / .ogg sound effects & ambience
```

- **Prefix:** `vr_<category>_<name>` in lowercase `snake_case`.
- **Export Formats:**
  - `.fbx` — Primary interchange format for **Roblox Studio** and **Unity** (supports rigged meshes + animations).
  - `.glb` — Optional lightweight preview/web/engine backup.

---

## 4. Shared Humanoid Rig Strategy
- Maintain **one master voxel humanoid skeleton** (`assets/blender/characters/vr_char_base_rig.blend`).
- All playable Role outfits and humanoid NPCs bind to this exact skeleton so every animation (`Idle`, `Walk`, `Run`, `DodgeRoll`, `Chop`, `Mine`, `SwordSlash`, `BowDraw`, `PlaceBlock`) is created once and shared across all roles.
- Include attachment socket bones (`Socket_HandR`, `Socket_HandL`, `Socket_Back`, `Socket_Head`) for equipping voxel tools, weapons, shields, and helmets.

---

## 5. Current Asset Inventory (`art/base-voxel-pack`)
All starter assets are procedurally reproducible via `tools/blender/build_voxel_pack.py` (Blender 5.3) and share `assets/textures/voxel_palette_v1.png`:

| Asset | Source `.blend` | Exports (`.fbx` & `.glb`) | Notes |
| :--- | :--- | :--- | :--- |
| **Base Voxel Character** | `assets/blender/characters/vr_char_base_rig.blend` | `assets/exports/characters/vr_char_base_rig.{fbx,glb}` | 1.8m humanoid rig + 3 actions (`Idle`, `Walk`, `Swing`) + attachment sockets |
| **Voxel Wood Axe** | `assets/blender/tools/vr_tool_axe_wood.blend` | `assets/exports/tools/vr_tool_axe_wood.{fbx,glb}` | Origin at leather grip for `Socket_HandR` |
| **Voxel Stone Pickaxe** | `assets/blender/tools/vr_tool_pickaxe_stone.blend` | `assets/exports/tools/vr_tool_pickaxe_stone.{fbx,glb}` | Origin at leather grip for `Socket_HandR` |
| **Voxel Campfire** | `assets/blender/props/vr_prop_campfire.blend` | `assets/exports/props/vr_prop_campfire.{fbx,glb}` | 1m × 1m stone ring, crossed logs, voxel flames |
| **Voxel Pine Tree** | `assets/blender/environment/vr_env_pine_tree.blend` | `assets/exports/environment/vr_env_pine_tree.{fbx,glb}` | ~3.8m stepped voxel pine tree |
| **Voxel Iron Ore Vein** | `assets/blender/environment/vr_env_iron_vein.blend` | `assets/exports/environment/vr_env_iron_vein.{fbx,glb}` | ~1.5m granite cluster with copper-iron voxel ore |

### Importing into Roblox Studio (Quick Steps)
1. In Roblox Studio, click **Avatar → Import 3D** (or **Home → Import 3D**) and select any `.fbx` under `assets/exports/`.
2. Textures are embedded automatically (`voxel_palette_v1.png`).
3. Set scale conversion to **`Studs` / `4x`** if you want `1 Blender meter = 4 Roblox studs` (1 voxel block).
4. For `vr_char_base_rig.fbx`, open **Plugins → Animation Editor** on the imported rig to preview/publish the baked `Idle`, `Walk`, and `Swing` animations!
