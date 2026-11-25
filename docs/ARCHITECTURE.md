# VoxelRealms — Technical Architecture

> **Status:** Living Document — update this file whenever you add or modify a Service, Controller, Config, or Remote.

## 1. High-Level Topology

```mermaid
flowchart LR
    subgraph Client["Client (StarterPlayerScripts/Client)"]
        CC["CameraController"]
        MC["MovementController"]
        BC["BuildController"]
        UI["UIController"]
    end

    subgraph Shared["Shared (ReplicatedStorage/Shared)"]
        CFG["Config/ (Roles, Blocks, Items)"]
        TYP["Types/ (--!strict contracts)"]
        NET["Network/ (Remotes Registry)"]
        UTL["Util/ (VoxelGrid Math)"]
    end

    subgraph Server["Server (ServerScriptService/Server)"]
        DS["DataService"]
        RS["RoleService"]
        SS["SurvivalService"]
        VS["VoxelBuildService"]
        IS["InventoryService"]
    end

    Client -->|"Intent (RemoteEvent)"| NET
    NET -->|"Validated State Updates"| Server
    Server -->|"Replicated State / Snapshots"| Client
    Client -.-> CFG
    Server -.-> CFG
```

---

## 2. Deterministic Boot Lifecycle
Both `src/server/init.server.luau` and `src/client/init.client.luau` boot modules in two explicit phases:
1. **`Init()` Phase:** Register remotes, initialize local tables, bind internal references. Must NOT yield or rely on another module's runtime state.
2. **`Start()` Phase:** Connect Roblox events (`PlayerAdded`, `Heartbeat`, input bindings), begin game loops, and safely call other Services/Controllers.

This eliminates race conditions even as the team grows to dozens of modules.

---

## 3. Domain Ownership Map (Multi-Developer Scaling)
Each developer or AI agent can own a specific domain folder with minimal overlap:

| Domain | Server Path | Client Path | Shared Dependencies |
| :--- | :--- | :--- | :--- |
| **Data & Persistence** | `src/server/Services/DataService` | — | `Types/PlayerTypes` |
| **Roleplay Roles** | `src/server/Services/RoleService` | `src/client/Controllers/UIController` | `Config/Roles`, `Network/Remotes` |
| **Survival Stats** | `src/server/Services/SurvivalService` | `src/client/Controllers/UIController` | `Types/SurvivalTypes`, `Network/Remotes` |
| **Voxel Building** | `src/server/Services/VoxelBuildService` | `src/client/Controllers/BuildController` | `Config/Blocks`, `Util/VoxelGrid`, `Network/Remotes` |
| **Camera & Movement** | — (anti-cheat checks later) | `CameraController`, `MovementController` | `Config/Constants` |
| **Inventory & Crafting** | `src/server/Services/InventoryService` | `src/client/Controllers/UIController` | `Config/Items`, `Network/Remotes` |

---

## 4. Network Registry (`src/shared/Network/Remotes.luau`)
All Client ↔ Server communication goes through `ReplicatedStorage.Remotes` managed by `src/shared/Network/Remotes.luau`.

| Remote Name | Direction | Purpose |
| :--- | :--- | :--- |
| `SelectRole` | Client → Server | Request switching/selecting a Role ID |
| `RoleUpdated` | Server → Client | Broadcast confirmed Role state to players |
| `PlaceVoxel` | Client → Server | Request placing a voxel block at a grid coordinate |
| `RemoveVoxel` | Client → Server | Request breaking/removing a voxel block at a grid coordinate |
| `SurvivalStateChanged` | Server → Client | Sync authoritative Health/Stamina/Hunger snapshot |
| `SetSprinting` | Client → Server | Toggle authoritative sprint state (drains stamina & applies role move speed) |
| `RequestDodge` | Client → Server | Request dodge dash stamina deduction with server cooldown validation |

*(Add every new remote here as it is implemented.)*

---

## 5. Voxel Grid Standard (`src/shared/Util/VoxelGrid.luau`)
- `VOXEL_SIZE_STUDS = 4` (`4×4×4` studs per block).
- World positions snap cleanly to integer grid coordinates `(gx, gy, gz)` via `VoxelGrid.worldToGrid(pos)` and `VoxelGrid.gridToWorld(gridPos)`.
- Placed blocks are keyed by string `"gx,gy,gz"` on the server (`VoxelBuildService`) for $O(1)$ lookup, collision validation, ownership checks, and delta persistence.
