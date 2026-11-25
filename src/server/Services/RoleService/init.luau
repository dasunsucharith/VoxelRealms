--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)
local Roles = require(Shared.Config.Roles)
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

local Server = ServerScriptService:WaitForChild("Server")
local DataService = require(Server.Services.DataService)

type RoleId = GameTypes.RoleId
type RoleDefinition = GameTypes.RoleDefinition
type PlayerProfile = GameTypes.PlayerProfile

local RoleService = {}
local playerRoles: { [Player]: RoleId } = {}

local function _setRole(player: Player, roleId: RoleId, persist: boolean): ()
	playerRoles[player] = roleId
	player:SetAttribute("RoleId", roleId)
	Remotes.GetEvent("RoleUpdated"):FireAllClients(player.UserId, roleId)

	if persist then
		DataService.UpdateProfile(player, function(profile: PlayerProfile)
			profile.roleId = roleId
		end)
	end
end

local function _initPlayer(player: Player): ()
	local profile = DataService.WaitForProfile(player)
	if not player:IsDescendantOf(Players) then
		return
	end

	local initialRole: RoleId = if profile then profile.roleId else Constants.DEFAULT_ROLE :: RoleId
	_setRole(player, initialRole, false)
end

function RoleService.GetPlayerRole(player: Player): RoleDefinition
	local roleId = playerRoles[player] or (Constants.DEFAULT_ROLE :: RoleId)
	return Roles[roleId]
end

function RoleService.Init(): ()
	-- Reserved for dependency setup.
end

function RoleService.Start(): ()
	local selectRoleRemote = Remotes.GetEvent("SelectRole")

	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(_initPlayer, player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		playerRoles[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if not playerRoles[player] then
			task.spawn(_initPlayer, player)
		end
	end

	selectRoleRemote.OnServerEvent:Connect(function(player: Player, requestedRoleId: unknown)
		if typeof(requestedRoleId) ~= "string" then
			return
		end

		local definition = (Roles :: { [string]: RoleDefinition })[requestedRoleId]
		if not definition then
			return
		end

		_setRole(player, definition.id, true)
	end)
end

return RoleService
