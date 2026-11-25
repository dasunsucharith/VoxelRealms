--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameTypes = require(Shared.Types.GameTypes)

type BlockId = GameTypes.BlockId
type BlockDefinition = GameTypes.BlockDefinition

local Blocks: { [BlockId]: BlockDefinition } = {
	grass = {
		id = "grass",
		displayName = "Grass Block",
		color = Color3.fromRGB(98, 168, 72),
		material = Enum.Material.SmoothPlastic,
		hardness = 1,
	},
	dirt = {
		id = "dirt",
		displayName = "Dirt Block",
		color = Color3.fromRGB(134, 96, 67),
		material = Enum.Material.SmoothPlastic,
		hardness = 1,
	},
	stone = {
		id = "stone",
		displayName = "Stone Block",
		color = Color3.fromRGB(138, 142, 148),
		material = Enum.Material.Slate,
		hardness = 3,
	},
	timber = {
		id = "timber",
		displayName = "Timber Log",
		color = Color3.fromRGB(115, 78, 48),
		material = Enum.Material.Wood,
		hardness = 2,
	},
	plank = {
		id = "plank",
		displayName = "Wood Plank",
		color = Color3.fromRGB(178, 134, 84),
		material = Enum.Material.WoodPlanks,
		hardness = 2,
	},
}

return table.freeze(Blocks)
