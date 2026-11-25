--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameTypes = require(Shared.Types.GameTypes)

type RecipeDefinition = GameTypes.RecipeDefinition

local Recipes: { RecipeDefinition } = {
	{
		id = "craft_planks",
		displayName = "Wood Planks (x4)",
		description = "Saw 2 Wood Logs into 4 Plank Blocks.",
		outputItemId = "plank_block",
		outputCount = 4,
		ingredients = {
			wood = 2,
		},
	},
	{
		id = "craft_timber",
		displayName = "Timber Beams (x2)",
		description = "Hew 2 Wood Logs into 2 sturdy Timber Blocks.",
		outputItemId = "timber_block",
		outputCount = 2,
		ingredients = {
			wood = 2,
		},
	},
	{
		id = "craft_stone_blocks",
		displayName = "Cut Stone (x3)",
		description = "Shape 2 Rough Stone into 3 Stone Blocks.",
		outputItemId = "stone_block",
		outputCount = 3,
		ingredients = {
			stone = 2,
		},
	},
	{
		id = "craft_campfire",
		displayName = "Campfire Kit (x1)",
		description = "Bundle Wood and Stone into a field rest kit.",
		outputItemId = "campfire_kit",
		outputCount = 1,
		ingredients = {
			wood = 4,
			stone = 3,
		},
	},
	{
		id = "architect_bulk_planks",
		displayName = "Master Planks (x4)",
		description = "Architect blueprint: craft 4 Plank Blocks from just 1 Wood Log.",
		outputItemId = "plank_block",
		outputCount = 4,
		ingredients = {
			wood = 1,
		},
		requiredRole = "architect",
	},
	{
		id = "blacksmith_reinforced_stone",
		displayName = "Forged Masonry (x6)",
		description = "Blacksmith technique: bind Stone and Iron Ore into 6 Stone Blocks.",
		outputItemId = "stone_block",
		outputCount = 6,
		ingredients = {
			stone = 1,
			iron_ore = 1,
		},
		requiredRole = "blacksmith",
	},
	{
		id = "alchemist_healing_tonic",
		displayName = "Healing Tonic (x2)",
		description = "Alchemist brew: distill Wild Herbs and Forest Berries into 2 Healing Tonics.",
		outputItemId = "healing_tonic",
		outputCount = 2,
		ingredients = {
			herb = 2,
			berry = 2,
		},
		requiredRole = "alchemist",
	},
	{
		id = "craft_roast_meat",
		displayName = "Roast Meat (x2)",
		description = "Cook 2 Raw Meat into hearty Roast Meat.",
		outputItemId = "roast_meat",
		outputCount = 2,
		ingredients = {
			raw_meat = 2,
		},
	},
	{
		id = "hunter_trail_feast",
		displayName = "Hunter's Trail Roast (x2)",
		description = "Hunter recipe: sear 1 Raw Meat and 1 Berry into 2 hearty Roast Meat.",
		outputItemId = "roast_meat",
		outputCount = 2,
		ingredients = {
			raw_meat = 1,
			berry = 1,
		},
		requiredRole = "hunter",
	},
}

return table.freeze(Recipes)
