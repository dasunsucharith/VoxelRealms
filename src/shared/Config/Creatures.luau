--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameTypes = require(Shared.Types.GameTypes)

type CreatureKind = GameTypes.CreatureKind
type CreatureConfig = GameTypes.CreatureConfig

local Creatures: { [CreatureKind]: CreatureConfig } = {
	slime = {
		kind = "slime",
		displayName = "Forest Voxel Slime",
		maxHealth = 45,
		moveSpeed = 8,
		damage = 8,
		attackCooldown = 1.4,
		attackRange = 5.5,
		aggroRange = 22,
		leashRange = 46,
		respawnSeconds = 25,
		dropItemId = "slime_gel",
		dropCount = 2,
	},
	wolf = {
		kind = "wolf",
		displayName = "Timber Voxel Wolf",
		maxHealth = 70,
		moveSpeed = 13.5,
		damage = 14,
		attackCooldown = 1.15,
		attackRange = 6.5,
		aggroRange = 28,
		leashRange = 56,
		respawnSeconds = 30,
		dropItemId = "raw_meat",
		dropCount = 2,
		bonusItemId = "wolf_pelt",
		bonusCount = 1,
	},
}

return table.freeze(Creatures)
