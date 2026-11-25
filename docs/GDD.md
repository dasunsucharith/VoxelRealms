# VoxelRealms — Game Design Document (GDD)

> **Status:** Living Document (v0.1 — Sprint 0)
> **Inspiration:** *Dawnlands* (open-world survival crafting, exploration, ancient biomes, action combat) + Voxel World & Building + Structured Multiplayer Roleplay.

---

## 1. High Concept
Players enter a mysterious voxel world of ancient biomes and wild creatures. Everyone must gather, craft, build shelter, and survive—but every player also chooses a **Role** that shapes their abilities, exclusive crafting recipes, and place in the community. Play solo, with friends, or in bustling roleplay settlements, switching freely between **Third-Person** (exploration & combat) and **First-Person** (precision voxel building & aiming).

---

## 2. Core Gameplay Loop
1. **Select a Role:** Choose an initial Role upon entering the realm (changeable later at a Role Shrine/Guild Hall with cooldown or progression rules).
2. **Explore & Gather:** Traverse Dawnlands-inspired voxel biomes (Emerald Plains, Whispering Woods, Ancient Ruins, Frost Peaks) to chop wood, mine stone/ore, and forage herbs.
3. **Survive:** Manage **Health**, **Stamina** (sprinting, dodging, gathering, attacking), and **Hunger**. Survive day/night hazards and wildlife/creatures.
4. **Build (Voxel Grid):** Claim or build shelters, outposts, workshops, and towns using grid-snapped voxel blocks (`4×4×4` studs = `1m` block) plus placeable Blender-crafted voxel props (campfires, anvils, chests, beds, torches).
5. **Roleplay & Cooperate:** Trade resources, craft role-exclusive gear/potions/blueprints, defend settlements together, and unlock higher-tier biomes and bosses.

---

## 3. Starter Roles (MVP Set)
Every player can perform basic survival actions (gather basic materials, craft starter tools, place basic blocks). Roles grant **identity, bonuses, and exclusive recipes**:

| Role ID | Display Name | Core Fantasy | Passive Perks | Exclusive / Signature Craftables |
| :--- | :--- | :--- | :--- | :--- |
| `architect` | **Architect** | Master town & fortress builder | +20% build reach, reduced block material cost | Reinforced stone/timber blocks, decorative roofs, bridges, banners |
| `blacksmith` | **Blacksmith** | Forgemaster & arms dealer | +20% mining speed, higher tool durability | Forged weapons, armor sets, repair anvil, metal tools |
| `hunter` | **Hunter** | Wilderness scout & tracker | +15% stamina regen, +10% movement speed | Longbows, arrows, traps, leather scout gear, trophy mounts |
| `alchemist` | **Alchemist** | Healer, cook & potion brewer | +25% forage yield, stronger food/potion buffs | Healing elixirs, stamina tonics, biome resistance stews, camp cauldron |

*(Additional roles such as Guardian, Merchant, and Enchanter are planned post-MVP via `src/shared/Config/Roles.luau`.)*

---

## 4. Camera & Controls
- **Third-Person (Default):** Over-the-shoulder action-survival view inspired by Dawnlands (ideal for exploration, melee combat, dodge rolling, and admiring voxel outfits).
- **First-Person (Toggle via `V` or scroll-in):** Clean precision view for placing/removing voxel blocks, inspecting interiors, and bow aiming.

---

## 5. Voxel World & Building Rules (Roblox MVP)
- **Voxel Grid Scale:** `1 Voxel Block = 4×4×4 studs` in Roblox (`1×1×1 meter` in Blender).
- **World Structure:** Handcrafted Dawnlands-style island biomes with resource nodes (respawning trees, boulders, ore veins, ruins) plus **grid-snapped voxel building** so performance stays rock-solid across PC, mobile, and console on Roblox.
- **Standalone PC Vision (Phase 2 — Unity + C#):** Once validated on Roblox, expand to a full Burst-compiled destructible voxel terrain world on Steam with dedicated servers and deeper modding/RP tools, reusing 100% of our Blender voxel art library.

---

## 6. MVP Milestones
- **Sprint 0 (Current):** Git repo, Rojo/Wally/Lint toolchain, CI, living docs, modular Luau skeleton.
- **Sprint 1 (Core Feel):** 1st/3rd person camera, movement + stamina, server-validated voxel block placement/removal.
- **Sprint 2 (Survival Loop):** Health/Stamina/Hunger, resource gathering (wood/stone/ore), inventory & crafting bench.
- **Sprint 3 (Roleplay Core):** 4 starter Roles, role perks & selection UI, cloud saves (`DataService`), starter Blender voxel assets.
- **Sprint 4 (Alpha Playtest):** Starter island biomes, 1–2 voxel creatures, basic combat, public Roblox playtest & Discord community launch.
