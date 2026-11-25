--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameTypes = require(Shared.Types.GameTypes)

type LifecycleModule = GameTypes.LifecycleModule

local ControllersFolder = script:WaitForChild("Controllers")

local CONTROLLER_ORDER = {
	"CameraController",
	"BuildController",
}

local loadedControllers: { { name: string, module: LifecycleModule } } = {}

-- 1. Init phase
for _, controllerName in ipairs(CONTROLLER_ORDER) do
	local controllerModuleScript = ControllersFolder:WaitForChild(controllerName)
	local controller = require(controllerModuleScript) :: LifecycleModule
	if controller.Init then
		controller.Init()
	end
	table.insert(loadedControllers, { name = controllerName, module = controller })
end

-- 2. Start phase
for _, entry in ipairs(loadedControllers) do
	if entry.module.Start then
		task.spawn(entry.module.Start)
	end
end

print("[VoxelRealms] Client booted cleanly.")
