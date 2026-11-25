--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameTypes = require(Shared.Types.GameTypes)

type ItemId = GameTypes.ItemId
type ItemDefinition = GameTypes.ItemDefinition

local Items: { [ItemId]: ItemDefinition } = {
	wood = {
		id = "wood",
		displayName = "Wood Log",
		category = "resource",
		description = "Chopped from voxel pine trees. Used for planks, timber, and campfires.",
		accentColor = Color3.fromRGB(130, 88, 52),
		maxStack = 99,
	},
	stone = {
		id = "stone",
		displayName = "Rough Stone",
		category = "resource",
		description = "Mined from rocky outcrops. Essential for sturdy stone structures.",
		accentColor = Color3.fromRGB(145, 150, 158),
		maxStack = 99,
	},
	iron_ore = {
		id = "iron_ore",
		displayName = "Iron Ore",
		category = "resource",
		description = "Raw ore prized by Blacksmiths for reinforced gear and masonry.",
		accentColor = Color3.fromRGB(185, 145, 110),
		maxStack = 99,
	},
	herb = {
		id = "herb",
		displayName = "Wild Herb",
		category = "resource",
		description = "Aromatic forest leaves gathered by Alchemists for potent tonics.",
		accentColor = Color3.fromRGB(85, 195, 115),
		maxStack = 99,
	},
	berry = {
		id = "berry",
		displayName = "Forest Berry",
		category = "consumable",
		description = "Sweet wild berries. Eat to restore +18 Hunger and +10 Stamina.",
		accentColor = Color3.fromRGB(215, 65, 95),
		maxStack = 50,
		hungerRestore = 18,
		staminaRestore = 10,
	},
	plank_block = {
		id = "plank_block",
		displayName = "Plank Block",
		category = "block",
		description = "Shaped wooden voxel planks ready for shelter building.",
		accentColor = Color3.fromRGB(178, 134, 84),
		maxStack = 99,
		blockId = "plank",
	},
	timber_block = {
		id = "timber_block",
		displayName = "Timber Block",
		category = "block",
		description = "Heavy voxel timber beam for strong walls and frames.",
		accentColor = Color3.fromRGB(115, 78, 48),
		maxStack = 99,
		blockId = "timber",
	},
	stone_block = {
		id = "stone_block",
		displayName = "Stone Block",
		category = "block",
		description = "Cut voxel stone block built to withstand wild nights.",
		accentColor = Color3.fromRGB(138, 142, 148),
		maxStack = 99,
		blockId = "stone",
	},
	healing_tonic = {
		id = "healing_tonic",
		displayName = "Healing Tonic",
		category = "consumable",
		description = "Alchemist brew. Restores +45 Health, +40 Stamina, and +10 Hunger.",
		accentColor = Color3.fromRGB(170, 100, 225),
		maxStack = 20,
		healthRestore = 45,
		staminaRestore = 40,
		hungerRestore = 10,
	},
	campfire_kit = {
		id = "campfire_kit",
		displayName = "Campfire Kit",
		category = "placeable",
		description = "Place a glowing Voxel Campfire in front of you. Lights the night & heals nearby players.",
		accentColor = Color3.fromRGB(240, 135, 50),
		maxStack = 10,
	},
}

return table.freeze(Items)
