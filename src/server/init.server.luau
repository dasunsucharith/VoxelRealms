--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

type LifecycleModule = GameTypes.LifecycleModule

local ServicesFolder = script:WaitForChild("Services")

local SERVICE_ORDER = {
	"RoleService",
	"SurvivalService",
	"InventoryService",
	"WorldService",
	"VoxelBuildService",
}

-- 1. Register network remotes before any Service initializes.
Remotes.InitServer()

local loadedServices: { { name: string, module: LifecycleModule } } = {}

-- 2. Init phase (synchronous, no cross-service runtime calls).
for _, serviceName in ipairs(SERVICE_ORDER) do
	local serviceModuleScript = ServicesFolder:WaitForChild(serviceName)
	local service = require(serviceModuleScript) :: LifecycleModule
	if service.Init then
		service.Init()
	end
	table.insert(loadedServices, { name = serviceName, module = service })
end

-- 3. Start phase (safe to connect events and call other services).
for _, entry in ipairs(loadedServices) do
	if entry.module.Start then
		task.spawn(entry.module.Start)
	end
end

print("[VoxelRealms] Server booted cleanly.")
