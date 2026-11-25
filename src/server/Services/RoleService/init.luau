--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)
local Roles = require(Shared.Config.Roles)
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

type RoleId = GameTypes.RoleId
type RoleDefinition = GameTypes.RoleDefinition

local RoleService = {}
local playerRoles: { [Player]: RoleId } = {}

local function _setRole(player: Player, roleId: RoleId): ()
	playerRoles[player] = roleId
	player:SetAttribute("RoleId", roleId)
	Remotes.GetEvent("RoleUpdated"):FireAllClients(player.UserId, roleId)
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
		_setRole(player, Constants.DEFAULT_ROLE :: RoleId)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		playerRoles[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if not playerRoles[player] then
			_setRole(player, Constants.DEFAULT_ROLE :: RoleId)
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

		_setRole(player, definition.id)
	end)
end

return RoleService
