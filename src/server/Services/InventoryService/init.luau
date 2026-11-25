--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local Recipes = require(Shared.Config.Recipes)
local Roles = require(Shared.Config.Roles)
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

local Server = ServerScriptService:WaitForChild("Server")
local DataService = require(Server.Services.DataService)
local RoleService = require(Server.Services.RoleService)
local SurvivalService = require(Server.Services.SurvivalService)

type ItemId = GameTypes.ItemId
type ItemDefinition = GameTypes.ItemDefinition
type InventoryMap = GameTypes.InventoryMap
type PlayerProfile = GameTypes.PlayerProfile
type RecipeDefinition = GameTypes.RecipeDefinition

local STARTER_ITEMS: InventoryMap = {
	wood = 6,
	stone = 4,
	berry = 3,
}

local InventoryService = {}
local inventories: { [Player]: InventoryMap } = {}
local recipesById: { [string]: RecipeDefinition } = {}

local function _syncInventory(player: Player, persist: boolean): ()
	local inv = inventories[player]
	if not inv then
		return
	end

	local snapshot = table.clone(inv)
	Remotes.GetEvent("InventoryUpdated"):FireClient(player, snapshot)

	if persist then
		DataService.UpdateProfile(player, function(profile: PlayerProfile)
			profile.inventory = snapshot
		end)
	end
end

local function _sendToast(player: Player, message: string, color: Color3?): ()
	Remotes.GetEvent("ToastNotification"):FireClient(player, message, color)
end

local function _initPlayer(player: Player): ()
	local profile = DataService.WaitForProfile(player)
	if not player:IsDescendantOf(Players) then
		return
	end

	if profile then
		inventories[player] = table.clone(profile.inventory)
	else
		inventories[player] = table.clone(STARTER_ITEMS)
	end

	_syncInventory(player, false)
end

function InventoryService.GetInventory(player: Player): InventoryMap
	local inv = inventories[player]
	if not inv then
		return {}
	end
	return table.clone(inv)
end

function InventoryService.AddItem(player: Player, itemId: ItemId, amount: number): number
	if amount <= 0 then
		return 0
	end

	local inv = inventories[player]
	local def = Items[itemId]
	if not inv or not def then
		return 0
	end

	local current = inv[itemId] or 0
	local nextAmount = math.min(def.maxStack, current + amount)
	local added = nextAmount - current
	inv[itemId] = nextAmount
	_syncInventory(player, true)
	return added
end

function InventoryService.HasItems(player: Player, required: { [ItemId]: number }): boolean
	local inv = inventories[player]
	if not inv then
		return false
	end

	for itemId, needed in pairs(required) do
		if (inv[itemId] or 0) < needed then
			return false
		end
	end

	return true
end

function InventoryService.RemoveItems(player: Player, toRemove: { [ItemId]: number }): boolean
	if not InventoryService.HasItems(player, toRemove) then
		return false
	end

	local inv = inventories[player]
	if not inv then
		return false
	end

	for itemId, amount in pairs(toRemove) do
		local remaining = (inv[itemId] or 0) - amount
		if remaining <= 0 then
			inv[itemId] = nil
		else
			inv[itemId] = remaining
		end
	end

	_syncInventory(player, true)
	return true
end

function InventoryService.Init(): ()
	for _, recipe in ipairs(Recipes) do
		recipesById[recipe.id] = recipe
	end
end

function InventoryService.Start(): ()
	local craftRemote = Remotes.GetEvent("CraftRecipe")
	local useItemRemote = Remotes.GetEvent("UseItem")

	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(_initPlayer, player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		inventories[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if not inventories[player] then
			task.spawn(_initPlayer, player)
		end
	end

	craftRemote.OnServerEvent:Connect(function(player: Player, rawRecipeId: unknown)
		if typeof(rawRecipeId) ~= "string" then
			return
		end

		local recipe = recipesById[rawRecipeId]
		if not recipe then
			return
		end

		if recipe.requiredRole then
			local playerRole = RoleService.GetPlayerRole(player)
			if playerRole.id ~= recipe.requiredRole then
				local requiredName = Roles[recipe.requiredRole].displayName
				_sendToast(
					player,
					string.format("Requires %s role to craft %s", requiredName, recipe.displayName),
					Color3.fromRGB(235, 110, 110)
				)
				return
			end
		end

		if not InventoryService.RemoveItems(player, recipe.ingredients) then
			_sendToast(player, "Not enough ingredients!", Color3.fromRGB(235, 145, 90))
			return
		end

		local added = InventoryService.AddItem(player, recipe.outputItemId, recipe.outputCount)
		local outputDef = Items[recipe.outputItemId]
		_sendToast(player, string.format("Crafted +%d %s", added, outputDef.displayName), Color3.fromRGB(115, 235, 155))
	end)

	useItemRemote.OnServerEvent:Connect(function(player: Player, rawItemId: unknown)
		if typeof(rawItemId) ~= "string" then
			return
		end

		local def = (Items :: { [string]: ItemDefinition })[rawItemId]
		if not def or def.category ~= "consumable" then
			return
		end

		local itemId = def.id
		if not InventoryService.RemoveItems(player, { [itemId] = 1 }) then
			return
		end

		SurvivalService.ModifyStats(player, def.healthRestore or 0, def.staminaRestore or 0, def.hungerRestore or 0)
		_sendToast(player, string.format("Used %s", def.displayName), def.accentColor)
	end)
end

return InventoryService
