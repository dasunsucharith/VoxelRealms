# Contributing to VoxelRealms

This project is designed for **parallel multi-developer and multi-AI collaboration** (Antigravity, Codex, Claude Code). Follow this workflow to keep `main` clean and conflict-free.

---

## 1. Branching Strategy
- `main` is **protected and always playable**. Never commit untested work directly to `main` once teammates join.
- Create one branch per task using clear prefixes:
  - `feat/<domain>-<short-desc>` (e.g., `feat/voxel-grid-placement`)
  - `fix/<short-desc>` (e.g., `fix/stamina-regen-desync`)
  - `art/<asset-name>` (e.g., `art/base-voxel-rig`)
  - `docs/<topic>` (e.g., `docs/survival-balancing`)
  - `chore/<task>` (e.g., `chore/update-wally-deps`)

---

## 2. Commit Message Convention (Conventional Commits)
Use clean prefixes so history and changelogs stay readable:
- `feat(roles): add Architect passive build reach bonus`
- `fix(voxel): prevent block placement inside player hitbox`
- `art(tools): add voxel stone pickaxe blend and fbx export`
- `docs(architecture): document PlaceVoxel remote payload`

---

## 3. Working With Multiple Developers Without Conflicts
1. **Claim a Domain:** Before starting a sprint task, assign a clear Service/Controller or Asset folder so two people don't edit the same files simultaneously.
2. **Contracts First:** If Feature A (server) and Feature B (client) need a new remote or type, merge the small contract PR (`src/shared/Types/` + `src/shared/Network/`) first.
3. **Never Save Code in `.rbxl`:** All scripts stay in `src/` synced via Rojo. Only terrain, lighting, and static world layout belong in `places/main.rbxl`.
4. **Keep Binary Assets in Git LFS:** Verify `git lfs status` before pushing `.blend`, `.fbx`, `.png`, or `.rbxl` files.

---

## 4. Pre-PR Quality Checklist
Run these checks locally before opening a Pull Request:
```powershell
stylua src          # Auto-format Luau files
stylua --check src  # Verify formatting passes CI
selene src          # Verify zero lint errors
```
Then confirm:
- [ ] All new/edited `.luau` files start with `--!strict`.
- [ ] Tested live in Roblox Studio via `rojo serve`.
- [ ] Updated `docs/ARCHITECTURE.md` / `docs/GDD.md` / `docs/CHANGELOG.md` as needed.
