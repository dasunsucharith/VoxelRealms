--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameTypes = require(Shared.Types.GameTypes)

type RoleId = GameTypes.RoleId
type RoleDefinition = GameTypes.RoleDefinition

local Roles: { [RoleId]: RoleDefinition } = {
	architect = {
		id = "architect",
		displayName = "Architect",
		summary = "Master builder with extended placement reach and exclusive architectural blocks.",
		accentColor = Color3.fromRGB(70, 160, 235),
		perks = {
			buildReachMultiplier = 1.2,
			miningSpeedMultiplier = 1.0,
			staminaRegenMultiplier = 1.0,
			moveSpeedMultiplier = 1.0,
			forageYieldMultiplier = 1.0,
		},
	},
	blacksmith = {
		id = "blacksmith",
		displayName = "Blacksmith",
		summary = "Forgemaster skilled in fast mining, durable tools, weapons, and armor.",
		accentColor = Color3.fromRGB(230, 120, 55),
		perks = {
			buildReachMultiplier = 1.0,
			miningSpeedMultiplier = 1.2,
			staminaRegenMultiplier = 1.0,
			moveSpeedMultiplier = 1.0,
			forageYieldMultiplier = 1.0,
		},
	},
	hunter = {
		id = "hunter",
		displayName = "Hunter",
		summary = "Agile wilderness scout with faster movement, stamina recovery, and ranged mastery.",
		accentColor = Color3.fromRGB(85, 185, 105),
		perks = {
			buildReachMultiplier = 1.0,
			miningSpeedMultiplier = 1.0,
			staminaRegenMultiplier = 1.15,
			moveSpeedMultiplier = 1.1,
			forageYieldMultiplier = 1.0,
		},
	},
	alchemist = {
		id = "alchemist",
		displayName = "Alchemist",
		summary = "Healer and brewer who gathers extra herbs and crafts potent elixirs and feasts.",
		accentColor = Color3.fromRGB(170, 100, 225),
		perks = {
			buildReachMultiplier = 1.0,
			miningSpeedMultiplier = 1.0,
			staminaRegenMultiplier = 1.0,
			moveSpeedMultiplier = 1.0,
			forageYieldMultiplier = 1.25,
		},
	},
}

return table.freeze(Roles)
