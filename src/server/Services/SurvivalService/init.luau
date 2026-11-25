--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

type SurvivalState = GameTypes.SurvivalState

local SurvivalService = {}
local playerStates: { [Player]: SurvivalState } = {}

local function _syncState(player: Player): ()
	local state = playerStates[player]
	if state then
		Remotes.GetEvent("SurvivalStateChanged"):FireClient(player, state)
	end
end

local function _initPlayer(player: Player): ()
	playerStates[player] = {
		health = Constants.DEFAULT_MAX_HEALTH,
		maxHealth = Constants.DEFAULT_MAX_HEALTH,
		stamina = Constants.DEFAULT_MAX_STAMINA,
		maxStamina = Constants.DEFAULT_MAX_STAMINA,
		hunger = Constants.DEFAULT_MAX_HUNGER,
		maxHunger = Constants.DEFAULT_MAX_HUNGER,
	}
	_syncState(player)
end

function SurvivalService.GetState(player: Player): SurvivalState?
	return playerStates[player]
end

function SurvivalService.Init(): ()
	-- Reserved for dependency setup.
end

function SurvivalService.Start(): ()
	Players.PlayerAdded:Connect(_initPlayer)

	Players.PlayerRemoving:Connect(function(player: Player)
		playerStates[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if not playerStates[player] then
			_initPlayer(player)
		end
	end
end

return SurvivalService
