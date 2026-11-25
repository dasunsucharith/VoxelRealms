# VoxelRealms — Online Multiplayer Alpha Release Checklist

Use this checklist when you are ready to publish your first **Online Multiplayer Alpha** to Roblox so friends and playtesters can join together with persistent Cloud DataStores.

---

## 1. Sync & Build a Clean Release Place
1. Ensure `main` is up to date and CI is green:
   ```powershell
   cd D:\Projects\VoxelRealms
   git checkout main
   git pull origin main
   stylua --check src
   selene src
   ```
2. Start `rojo serve`, open `places/main.rbxl` in Roblox Studio, and click **Plugins → Rojo → Connect** so all scripts are synced into Studio before publishing.

---

## 2. Publish to Roblox Cloud
1. In Roblox Studio, go to **File → Publish to Roblox As...** → click **Create new game**.
2. Name it **`VoxelRealms (Alpha)`**, set Genre to **RPG / Survival**, and set **Max Players** to **12–16** (ideal for cozy survival roleplay).
3. Click **Create / Publish**.
   *(Tip: Keep `places/main.rbxl` on disk clean for local Rojo dev — never edit scripts directly in Studio!)*

---

## 3. Enable Live Cloud DataStores (`DataService`)
1. In Roblox Studio (with the published experience open), click **Home → Game Settings → Security**.
2. Toggle **Enable Studio Access to API Services** → **ON** and click **Save**.
3. Hit **Play (F5)** and confirm Output logs:
   `[DataService] Cloud DataStore persistence active.`
4. Test persistence: switch Role (`[R]`), gather some wood (`[E]`), stop Play, hit Play again — your Role and Inventory should restore automatically!

---

## 4. Invite Playtesters & Collect Feedback
1. Go to **Game Settings → Permissions** → set to **Friends** (or **Public** when ready) and share the Roblox Experience link.
2. Create a simple **VoxelRealms Discord Server** with `#announcements`, `#bug-reports`, and `#role-ideas` — this is the community you will also invite when launching the future **Standalone PC Edition (Unity + C#)**!
3. Track key Alpha validation metrics:
   - Do players immediately understand **Roles + Gathering + Building + Campfires + Combat**?
   - Which Roles do players pick most/least?
   - Average session length & Day-7 return rate.
