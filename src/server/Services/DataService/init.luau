--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)
local Items = require(Shared.Config.Items)
local Roles = require(Shared.Config.Roles)
local GameTypes = require(Shared.Types.GameTypes)

type ItemId = GameTypes.ItemId
type ItemDefinition = GameTypes.ItemDefinition
type InventoryMap = GameTypes.InventoryMap
type PlayerProfile = GameTypes.PlayerProfile
type RoleId = GameTypes.RoleId
type RoleDefinition = GameTypes.RoleDefinition

local DATASTORE_NAME = "VoxelRealms_PlayerData_v1"
local SCHEMA_VERSION = 1
local MAX_RETRIES = 3
local AUTOSAVE_INTERVAL_SEC = 120
local LOAD_WAIT_TIMEOUT_SEC = 15

local STARTER_INVENTORY: InventoryMap = {
	wood = 6,
	stone = 4,
	berry = 3,
}

local DataService = {}
local dataStore: DataStore? = nil
local isCloudEnabled = false

local profiles: { [Player]: PlayerProfile } = {}
local loadingPlayers: { [Player]: boolean } = {}
local dirtyPlayers: { [Player]: boolean } = {}

local function _makeDefaultProfile(): PlayerProfile
	return {
		schemaVersion = SCHEMA_VERSION,
		roleId = Constants.DEFAULT_ROLE :: RoleId,
		inventory = table.clone(STARTER_INVENTORY),
		health = Constants.DEFAULT_MAX_HEALTH,
		hunger = Constants.DEFAULT_MAX_HUNGER,
	}
end

local function _reconcileProfile(raw: unknown): PlayerProfile
	local profile = _makeDefaultProfile()
	if typeof(raw) ~= "table" then
		return profile
	end

	local rawTable = raw :: { [string]: unknown }

	if typeof(rawTable.roleId) == "string" and (Roles :: { [string]: RoleDefinition })[rawTable.roleId] then
		profile.roleId = rawTable.roleId :: RoleId
	end

	if typeof(rawTable.inventory) == "table" then
		local sanitized: InventoryMap = {}
		for key, value in pairs(rawTable.inventory :: { [unknown]: unknown }) do
			if typeof(key) == "string" and typeof(value) == "number" then
				local def = (Items :: { [string]: ItemDefinition })[key]
				if def then
					local clamped = math.clamp(math.floor(value), 0, def.maxStack)
					if clamped > 0 then
						sanitized[def.id] = clamped
					end
				end
			end
		end
		profile.inventory = sanitized
	end

	if typeof(rawTable.health) == "number" then
		local clampedHealth = math.clamp(rawTable.health, 1, Constants.DEFAULT_MAX_HEALTH)
		profile.health = clampedHealth
	end

	if typeof(rawTable.hunger) == "number" then
		profile.hunger = math.clamp(rawTable.hunger, 0, Constants.DEFAULT_MAX_HUNGER)
	end

	profile.schemaVersion = SCHEMA_VERSION
	return profile
end

local function _profileKey(userId: number): string
	return "player_" .. tostring(userId)
end

local function _loadPlayer(player: Player): ()
	loadingPlayers[player] = true
	local key = _profileKey(player.UserId)
	local loadedRaw: unknown = nil

	if isCloudEnabled and dataStore then
		local store = dataStore :: DataStore
		for attempt = 1, MAX_RETRIES do
			local ok, result = pcall(function()
				return store:GetAsync(key)
			end)
			if ok then
				loadedRaw = result
				break
			end
			warn(
				string.format("[DataService] Load attempt %d failed for %s: %s", attempt, player.Name, tostring(result))
			)
			task.wait(attempt * 0.75)
		end
	end

	if not player:IsDescendantOf(Players) then
		loadingPlayers[player] = nil
		return
	end

	profiles[player] = _reconcileProfile(loadedRaw)
	dirtyPlayers[player] = false
	loadingPlayers[player] = nil
end

function DataService.GetProfile(player: Player): PlayerProfile?
	return profiles[player]
end

function DataService.WaitForProfile(player: Player): PlayerProfile?
	local deadline = os.clock() + LOAD_WAIT_TIMEOUT_SEC
	while profiles[player] == nil and player:IsDescendantOf(Players) and os.clock() < deadline do
		if not loadingPlayers[player] then
			break
		end
		task.wait(0.05)
	end
	return profiles[player]
end

function DataService.UpdateProfile(player: Player, mutator: (profile: PlayerProfile) -> ()): ()
	local profile = profiles[player]
	if not profile then
		return
	end
	mutator(profile)
	dirtyPlayers[player] = true
end

function DataService.SavePlayer(player: Player): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end

	if not isCloudEnabled or not dataStore then
		dirtyPlayers[player] = false
		return true
	end

	local snapshot: PlayerProfile = {
		schemaVersion = profile.schemaVersion,
		roleId = profile.roleId,
		inventory = table.clone(profile.inventory),
		health = profile.health,
		hunger = profile.hunger,
	}

	local key = _profileKey(player.UserId)
	local store = dataStore :: DataStore

	for attempt = 1, MAX_RETRIES do
		local ok, err = pcall(function()
			store:UpdateAsync(key, function()
				return snapshot
			end)
		end)
		if ok then
			dirtyPlayers[player] = false
			return true
		end
		warn(string.format("[DataService] Save attempt %d failed for %s: %s", attempt, player.Name, tostring(err)))
		task.wait(attempt * 0.75)
	end

	return false
end

function DataService.Init(): ()
	local ok, storeOrErr = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)

	if ok and storeOrErr then
		-- Probe read permission cleanly so unpublished local Studio shells fall back gracefully
		local probeOk = pcall(function()
			(storeOrErr :: DataStore):GetAsync("__voxelrealms_healthcheck__")
		end)
		if probeOk then
			dataStore = storeOrErr :: DataStore
			isCloudEnabled = true
			print("[DataService] Cloud DataStore persistence active.")
		else
			isCloudEnabled = false
			print("[DataService] Studio offline mode detected — using in-memory session profiles.")
		end
	else
		isCloudEnabled = false
		print("[DataService] DataStore unavailable — using in-memory session profiles.")
	end
end

function DataService.Start(): ()
	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(_loadPlayer, player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if not profiles[player] and not loadingPlayers[player] then
			task.spawn(_loadPlayer, player)
		end
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		DataService.SavePlayer(player)
		profiles[player] = nil
		loadingPlayers[player] = nil
		dirtyPlayers[player] = nil
	end)

	-- Periodic background autosave for dirty profiles
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL_SEC)
			for player, isDirty in pairs(dirtyPlayers) do
				if isDirty and player:IsDescendantOf(Players) then
					task.spawn(DataService.SavePlayer, player)
				end
			end
		end
	end)

	-- Flush all active profiles cleanly on server shutdown
	game:BindToClose(function()
		if RunService:IsStudio() and not isCloudEnabled then
			return
		end

		local activePlayers = Players:GetPlayers()
		local remaining = #activePlayers
		if remaining == 0 then
			return
		end

		for _, player in ipairs(activePlayers) do
			task.spawn(function()
				DataService.SavePlayer(player)
				remaining -= 1
			end)
		end

		local deadline = os.clock() + 10
		while remaining > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
