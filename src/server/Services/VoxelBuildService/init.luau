--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Blocks = require(Shared.Config.Blocks)
local Constants = require(Shared.Config.Constants)
local Remotes = require(Shared.Network.Remotes)
local VoxelGrid = require(Shared.Util.VoxelGrid)
local GameTypes = require(Shared.Types.GameTypes)

local Server = ServerScriptService:WaitForChild("Server")
local RoleService = require(Server.Services.RoleService)

type BlockDefinition = GameTypes.BlockDefinition

local VoxelBuildService = {}
local placedBlocks: { [string]: BasePart } = {}
local worldFolder: Folder

local function _getPlayerOrigin(player: Player): Vector3?
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

local function _getPlayerReach(player: Player): number
	local role = RoleService.GetPlayerRole(player)
	return Constants.BASE_BUILD_REACH_STUDS * role.perks.buildReachMultiplier
end

function VoxelBuildService.Init(): ()
	local existing = Workspace:FindFirstChild("VoxelWorld")
	if existing and existing:IsA("Folder") then
		worldFolder = existing
	else
		local folder = Instance.new("Folder")
		folder.Name = "VoxelWorld"
		folder.Parent = Workspace
		worldFolder = folder
	end
end

function VoxelBuildService.Start(): ()
	local placeRemote = Remotes.GetEvent("PlaceVoxel")
	local removeRemote = Remotes.GetEvent("RemoveVoxel")

	placeRemote.OnServerEvent:Connect(function(player: Player, rawGridCoord: unknown, rawBlockId: unknown)
		if typeof(rawGridCoord) ~= "Vector3" or typeof(rawBlockId) ~= "string" then
			return
		end

		local blockDef = (Blocks :: { [string]: BlockDefinition })[rawBlockId]
		if not blockDef then
			return
		end

		local origin = _getPlayerOrigin(player)
		if not origin or not VoxelGrid.isWithinReach(origin, rawGridCoord, _getPlayerReach(player)) then
			return
		end

		local key = VoxelGrid.gridToKey(rawGridCoord)
		if placedBlocks[key] then
			return
		end

		local size = Constants.VOXEL_SIZE_STUDS
		local part = Instance.new("Part")
		part.Name = string.format("Voxel_%s_%s", blockDef.id, key)
		part.Size = Vector3.new(size, size, size)
		part.Position = VoxelGrid.gridToWorld(rawGridCoord)
		part.Anchored = true
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Color = blockDef.color
		part.Material = blockDef.material
		part:SetAttribute("BlockId", blockDef.id)
		part:SetAttribute("OwnerUserId", player.UserId)
		part.Parent = worldFolder

		placedBlocks[key] = part
	end)

	removeRemote.OnServerEvent:Connect(function(player: Player, rawGridCoord: unknown)
		if typeof(rawGridCoord) ~= "Vector3" then
			return
		end

		local origin = _getPlayerOrigin(player)
		if not origin or not VoxelGrid.isWithinReach(origin, rawGridCoord, _getPlayerReach(player)) then
			return
		end

		local key = VoxelGrid.gridToKey(rawGridCoord)
		local existing = placedBlocks[key]
		if existing then
			existing:Destroy()
			placedBlocks[key] = nil
		end
	end)
end

return VoxelBuildService
