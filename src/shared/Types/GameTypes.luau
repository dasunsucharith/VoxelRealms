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

export type ItemId =
	"wood"
	| "stone"
	| "iron_ore"
	| "herb"
	| "berry"
	| "plank_block"
	| "stone_block"
	| "timber_block"
	| "healing_tonic"
	| "campfire_kit"

export type ItemCategory = "resource" | "block" | "consumable" | "placeable"

export type ItemDefinition = {
	id: ItemId,
	displayName: string,
	category: ItemCategory,
	description: string,
	accentColor: Color3,
	maxStack: number,
	healthRestore: number?,
	staminaRestore: number?,
	hungerRestore: number?,
	blockId: BlockId?,
}

export type InventoryMap = { [ItemId]: number }

export type RecipeDefinition = {
	id: string,
	displayName: string,
	description: string,
	outputItemId: ItemId,
	outputCount: number,
	ingredients: { [ItemId]: number },
	requiredRole: RoleId?,
}

export type ResourceNodeKind = "tree" | "stone_rock" | "iron_vein" | "herb_bush"
export type GatherAction = "chop" | "mine" | "forage"

export type ResourceNodeConfig = {
	kind: ResourceNodeKind,
	displayName: string,
	actionLabel: string,
	gatherAction: GatherAction,
	maxHealth: number,
	respawnSeconds: number,
	dropItemId: ItemId,
	baseYield: number,
	bonusItemId: ItemId?,
	bonusYield: number?,
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
