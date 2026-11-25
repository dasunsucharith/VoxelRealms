# Changelog

All notable changes to **VoxelRealms** are documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Initialized `VoxelRealms` multi-developer Git + Git LFS repository.
- Configured Roblox toolchain (`rokit.toml`, `default.project.json`, `wally.toml`, `stylua.toml`, `selene.toml`) and GitHub Actions CI (`ci.yml`).
- Added shared AI agent instructions (`AGENTS.md`, `CLAUDE.md`) for Antigravity, Codex, and Claude Code.
- Added living documentation (`docs/GDD.md`, `docs/ARCHITECTURE.md`, `docs/ASSET_PIPELINE.md`, `docs/CONTRIBUTING.md`).
- Scaffolded modular Luau architecture (`src/shared`, `src/server/Services`, `src/client/Controllers`) with strict typing (`--!strict`), deterministic `Init`/`Start` bootstrappers, starter Role/Block configs, and VoxelGrid math utilities.
