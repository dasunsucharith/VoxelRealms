--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameTypes = require(Shared.Types.GameTypes)

type ResourceNodeKind = GameTypes.ResourceNodeKind
type ResourceNodeConfig = GameTypes.ResourceNodeConfig

local ResourceNodes: { [ResourceNodeKind]: ResourceNodeConfig } = {
	tree = {
		kind = "tree",
		displayName = "Voxel Pine Tree",
		actionLabel = "Chop",
		gatherAction = "chop",
		maxHealth = 30,
		respawnSeconds = 20,
		dropItemId = "wood",
		baseYield = 3,
	},
	stone_rock = {
		kind = "stone_rock",
		displayName = "Stone Boulder",
		actionLabel = "Mine",
		gatherAction = "mine",
		maxHealth = 40,
		respawnSeconds = 25,
		dropItemId = "stone",
		baseYield = 3,
	},
	iron_vein = {
		kind = "iron_vein",
		displayName = "Iron Ore Vein",
		actionLabel = "Mine",
		gatherAction = "mine",
		maxHealth = 50,
		respawnSeconds = 35,
		dropItemId = "iron_ore",
		baseYield = 2,
		bonusItemId = "stone",
		bonusYield = 1,
	},
	herb_bush = {
		kind = "herb_bush",
		displayName = "Wild Berry & Herb Bush",
		actionLabel = "Forage",
		gatherAction = "forage",
		maxHealth = 20,
		respawnSeconds = 18,
		dropItemId = "herb",
		baseYield = 2,
		bonusItemId = "berry",
		bonusYield = 2,
	},
}

return table.freeze(ResourceNodes)
