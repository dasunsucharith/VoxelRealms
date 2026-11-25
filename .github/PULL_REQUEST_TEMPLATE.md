## Summary
<!-- Describe what this PR adds or changes in 1–3 sentences. -->

## Domain / System Touched
- [ ] `src/shared` (Config / Types / Network / Util)
- [ ] `src/server/Services` (Specify service: `...`)
- [ ] `src/client/Controllers` (Specify controller: `...`)
- [ ] `assets/` (Blender / FBX / Textures / Audio)
- [ ] `docs/` (Documentation)

## Multi-Dev & Quality Checklist
- [ ] Every new/edited `.luau` file uses `--!strict`
- [ ] Game balance/items/roles live in `src/shared/Config/` (not hardcoded in logic)
- [ ] Ran `stylua --check src` and `selene src` with zero errors
- [ ] Updated `docs/ARCHITECTURE.md` (if services, controllers, or remotes changed)
- [ ] Updated `docs/CHANGELOG.md`
- [ ] Verified in Roblox Studio via `rojo serve`
