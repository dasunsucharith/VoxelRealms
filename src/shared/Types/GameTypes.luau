--!strict

export type RoleId = "architect" | "blacksmith" | "hunter" | "alchemist"

export type RolePerks = {
	buildReachMultiplier: number,
	miningSpeedMultiplier: number,
	staminaRegenMultiplier: number,
	moveSpeedMultiplier: number,
	forageYieldMultiplier: number,
}

export type RoleDefinition = {
	id: RoleId,
	displayName: string,
	summary: string,
	accentColor: Color3,
	perks: RolePerks,
}

export type BlockId = "grass" | "dirt" | "stone" | "timber" | "plank"

export type BlockDefinition = {
	id: BlockId,
	displayName: string,
	color: Color3,
	material: Enum.Material,
	hardness: number,
}

export type SurvivalState = {
	health: number,
	maxHealth: number,
	stamina: number,
	maxStamina: number,
	hunger: number,
	maxHunger: number,
}

export type LifecycleModule = {
	Init: (() -> ())?,
	Start: (() -> ())?,
}

return {}
