--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

local Server = ServerScriptService:WaitForChild("Server")
local RoleService = require(Server.Services.RoleService)

type SurvivalState = GameTypes.SurvivalState

type RuntimePlayerData = {
	state: SurvivalState,
	isSprinting: boolean,
	lastStaminaUse: number,
	lastDodgeTime: number,
	lastSyncTime: number,
}

local SYNC_INTERVAL_SEC = 0.1

local SurvivalService = {}
local runtimeData: { [Player]: RuntimePlayerData } = {}

local function _getHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid
end

local function _applyWalkSpeed(player: Player, data: RuntimePlayerData): ()
	local humanoid = _getHumanoid(player)
	if not humanoid then
		return
	end

	local role = RoleService.GetPlayerRole(player)
	local baseSpeed = if data.isSprinting then Constants.SPRINT_SPEED else Constants.WALK_SPEED
	humanoid.WalkSpeed = baseSpeed * role.perks.moveSpeedMultiplier
end

local function _syncState(player: Player, data: RuntimePlayerData): ()
	data.lastSyncTime = os.clock()
	Remotes.GetEvent("SurvivalStateChanged"):FireClient(player, data.state)
end

local function _bindCharacter(player: Player, character: Model): ()
	local data = runtimeData[player]
	if not data then
		return
	end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end

	humanoid.MaxHealth = data.state.maxHealth
	humanoid.Health = data.state.maxHealth
	data.state.health = humanoid.Health
	data.state.stamina = data.state.maxStamina
	data.isSprinting = false
	_applyWalkSpeed(player, data)
	_syncState(player, data)

	humanoid.HealthChanged:Connect(function(newHealth: number)
		local current = runtimeData[player]
		if current then
			current.state.health = math.clamp(newHealth, 0, current.state.maxHealth)
			_syncState(player, current)
		end
	end)
end

local function _initPlayer(player: Player): ()
	local now = os.clock()
	local data: RuntimePlayerData = {
		state = {
			health = Constants.DEFAULT_MAX_HEALTH,
			maxHealth = Constants.DEFAULT_MAX_HEALTH,
			stamina = Constants.DEFAULT_MAX_STAMINA,
			maxStamina = Constants.DEFAULT_MAX_STAMINA,
			hunger = Constants.DEFAULT_MAX_HUNGER,
			maxHunger = Constants.DEFAULT_MAX_HUNGER,
		},
		isSprinting = false,
		lastStaminaUse = 0,
		lastDodgeTime = 0,
		lastSyncTime = now,
	}

	runtimeData[player] = data
	_syncState(player, data)

	player.CharacterAdded:Connect(function(character: Model)
		_bindCharacter(player, character)
	end)

	if player.Character then
		task.spawn(_bindCharacter, player, player.Character)
	end
end

function SurvivalService.GetState(player: Player): SurvivalState?
	local data = runtimeData[player]
	return if data then data.state else nil
end

function SurvivalService.ModifyStats(player: Player, healthDelta: number, staminaDelta: number, hungerDelta: number): ()
	local data = runtimeData[player]
	if not data then
		return
	end

	if healthDelta ~= 0 then
		data.state.health = math.clamp(data.state.health + healthDelta, 0, data.state.maxHealth)
		local humanoid = _getHumanoid(player)
		if humanoid then
			humanoid.Health = data.state.health
		end
	end

	if staminaDelta ~= 0 then
		data.state.stamina = math.clamp(data.state.stamina + staminaDelta, 0, data.state.maxStamina)
	end

	if hungerDelta ~= 0 then
		data.state.hunger = math.clamp(data.state.hunger + hungerDelta, 0, data.state.maxHunger)
	end

	_syncState(player, data)
end

function SurvivalService.Init(): ()
	-- Reserved for dependency setup.
end

function SurvivalService.Start(): ()
	local setSprintingRemote = Remotes.GetEvent("SetSprinting")
	local requestDodgeRemote = Remotes.GetEvent("RequestDodge")

	Players.PlayerAdded:Connect(_initPlayer)

	Players.PlayerRemoving:Connect(function(player: Player)
		runtimeData[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if not runtimeData[player] then
			_initPlayer(player)
		end
	end

	setSprintingRemote.OnServerEvent:Connect(function(player: Player, wantsSprint: unknown)
		if typeof(wantsSprint) ~= "boolean" then
			return
		end

		local data = runtimeData[player]
		if not data then
			return
		end

		if wantsSprint and data.state.stamina > 5 then
			data.isSprinting = true
		else
			data.isSprinting = false
		end
		_applyWalkSpeed(player, data)
	end)

	requestDodgeRemote.OnServerEvent:Connect(function(player: Player)
		local data = runtimeData[player]
		if not data then
			return
		end

		local now = os.clock()
		if now - data.lastDodgeTime < Constants.DODGE_COOLDOWN_SEC then
			return
		end

		if data.state.stamina < Constants.DODGE_STAMINA_COST then
			return
		end

		data.lastDodgeTime = now
		data.lastStaminaUse = now
		data.state.stamina = math.max(0, data.state.stamina - Constants.DODGE_STAMINA_COST)
		_syncState(player, data)
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()

		for player, data in pairs(runtimeData) do
			local role = RoleService.GetPlayerRole(player)
			local humanoid = _getHumanoid(player)
			local isMoving = if humanoid then humanoid.MoveDirection.Magnitude > 0.1 else false

			-- Stamina drain / regeneration
			if data.isSprinting and isMoving then
				data.state.stamina = math.max(0, data.state.stamina - (Constants.SPRINT_STAMINA_DRAIN_PER_SEC * dt))
				data.lastStaminaUse = now
				if data.state.stamina <= 0 then
					data.isSprinting = false
				end
			elseif now - data.lastStaminaUse >= Constants.STAMINA_REGEN_DELAY_SEC then
				local regenRate = Constants.STAMINA_REGEN_PER_SEC * role.perks.staminaRegenMultiplier
				data.state.stamina = math.min(data.state.maxStamina, data.state.stamina + (regenRate * dt))
			end

			-- Gentle hunger drain
			data.state.hunger = math.max(0, data.state.hunger - (Constants.HUNGER_DRAIN_PER_SEC * dt))

			-- Keep walkspeed synced with role perks + sprint state
			_applyWalkSpeed(player, data)

			if now - data.lastSyncTime >= SYNC_INTERVAL_SEC then
				_syncState(player, data)
			end
		end
	end)
end

return SurvivalService
