--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameTypes = require(Shared.Types.GameTypes)

type ToolId = GameTypes.ToolId
type ToolDefinition = GameTypes.ToolDefinition

local Tools: { [ToolId]: ToolDefinition } = {
	axe = {
		id = "axe",
		displayName = "Voxel Wood Axe",
		specialty = "chop",
		bonusMultiplier = 1.35,
		description = "+35% chopping speed on Voxel Pine Trees.",
		accentColor = Color3.fromRGB(184, 138, 86),
	},
	pickaxe = {
		id = "pickaxe",
		displayName = "Voxel Stone Pickaxe",
		specialty = "mine",
		bonusMultiplier = 1.35,
		description = "+35% mining speed on Stone Boulders & Iron Veins.",
		accentColor = Color3.fromRGB(156, 166, 178),
	},
	sword = {
		id = "sword",
		displayName = "Voxel Broadsword",
		specialty = "combat",
		bonusMultiplier = 1.35,
		description = "+35% melee damage against Timber Wolves & Forest Slimes.",
		accentColor = Color3.fromRGB(224, 184, 82),
	},
}

return table.freeze(Tools)
