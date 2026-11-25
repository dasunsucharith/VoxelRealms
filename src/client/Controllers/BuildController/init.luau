--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Blocks = require(Shared.Config.Blocks)
local Constants = require(Shared.Config.Constants)
local Roles = require(Shared.Config.Roles)
local Remotes = require(Shared.Network.Remotes)
local VoxelGrid = require(Shared.Util.VoxelGrid)
local GameTypes = require(Shared.Types.GameTypes)

type BlockId = GameTypes.BlockId
type RoleId = GameTypes.RoleId
type RoleDefinition = GameTypes.RoleDefinition

local HOTBAR_KEY_MAP: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
}

local VALID_GHOST_COLOR = Color3.fromRGB(90, 235, 130)
local INVALID_GHOST_COLOR = Color3.fromRGB(235, 85, 85)
local MAX_RAY_DISTANCE = 150

local BuildController = {}
local localPlayer = Players.LocalPlayer
local activeBlockId: BlockId = "plank"
local isBuildModeEnabled = true

local ghostPart: Part
local ghostOutline: SelectionBox
local currentPlaceGrid: Vector3? = nil
local currentRemoveGrid: Vector3? = nil
local currentCanPlace = false

local function _getPlayerReach(): number
	local roleAttr = localPlayer:GetAttribute("RoleId")
	local roleId: RoleId = if typeof(roleAttr) == "string" and (Roles :: { [string]: RoleDefinition })[roleAttr]
		then roleAttr :: RoleId
		else Constants.DEFAULT_ROLE :: RoleId
	return Constants.BASE_BUILD_REACH_STUDS * Roles[roleId].perks.buildReachMultiplier
end

local function _getPlayerOrigin(): Vector3?
	local character = localPlayer.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

local function _raycastMouse(): RaycastResult?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end

	local mouseLocation = UserInputService:GetMouseLocation()
	local unitRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	local filterList: { Instance } = { ghostPart }
	if localPlayer.Character then
		table.insert(filterList, localPlayer.Character)
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = filterList

	return Workspace:Raycast(unitRay.Origin, unitRay.Direction * MAX_RAY_DISTANCE, params)
end

local function _updateGhostPreview(): ()
	if not isBuildModeEnabled then
		ghostPart.Parent = nil
		currentPlaceGrid = nil
		currentRemoveGrid = nil
		currentCanPlace = false
		return
	end

	local result = _raycastMouse()
	local origin = _getPlayerOrigin()
	if not result or not origin then
		ghostPart.Parent = nil
		currentPlaceGrid = nil
		currentRemoveGrid = nil
		currentCanPlace = false
		return
	end

	local voxelSize = Constants.VOXEL_SIZE_STUDS
	local placeWorldPos = result.Position + (result.Normal * (voxelSize * 0.5))
	local placeGrid = VoxelGrid.worldToGrid(placeWorldPos)
	local reach = _getPlayerReach()
	local withinReach = VoxelGrid.isWithinReach(origin, placeGrid, reach)

	-- Track removable voxel if hovering an existing placed block
	local hitInstance = result.Instance
	local voxelWorld = Workspace:FindFirstChild("VoxelWorld")
	if voxelWorld and hitInstance:IsDescendantOf(voxelWorld) and hitInstance:IsA("BasePart") then
		local removeGrid = VoxelGrid.worldToGrid(hitInstance.Position)
		if VoxelGrid.isWithinReach(origin, removeGrid, reach) then
			currentRemoveGrid = removeGrid
		else
			currentRemoveGrid = nil
		end
	else
		currentRemoveGrid = nil
	end

	currentPlaceGrid = placeGrid
	currentCanPlace = withinReach

	local blockDef = Blocks[activeBlockId]
	ghostPart.Position = VoxelGrid.gridToWorld(placeGrid)
	ghostPart.Color = if withinReach then blockDef.color else INVALID_GHOST_COLOR
	ghostOutline.Color3 = if withinReach then VALID_GHOST_COLOR else INVALID_GHOST_COLOR
	ghostPart.Parent = Workspace
end

function BuildController.SetActiveBlock(blockId: BlockId): ()
	activeBlockId = blockId
	localPlayer:SetAttribute("ActiveBlockId", blockId)
end

function BuildController.SetBuildMode(enabled: boolean): ()
	isBuildModeEnabled = enabled
	localPlayer:SetAttribute("BuildModeEnabled", enabled)
	if not enabled then
		ghostPart.Parent = nil
	end
end

function BuildController.RequestPlace(gridCoord: Vector3): ()
	Remotes.GetEvent("PlaceVoxel"):FireServer(gridCoord, activeBlockId)
end

function BuildController.RequestRemove(gridCoord: Vector3): ()
	Remotes.GetEvent("RemoveVoxel"):FireServer(gridCoord)
end

function BuildController.Init(): ()
	local size = Constants.VOXEL_SIZE_STUDS
	ghostPart = Instance.new("Part")
	ghostPart.Name = "VoxelGhostPreview"
	ghostPart.Size = Vector3.new(size, size, size)
	ghostPart.Anchored = true
	ghostPart.CanCollide = false
	ghostPart.CanQuery = false
	ghostPart.CanTouch = false
	ghostPart.CastShadow = false
	ghostPart.Transparency = 0.55
	ghostPart.Material = Enum.Material.SmoothPlastic

	ghostOutline = Instance.new("SelectionBox")
	ghostOutline.LineThickness = 0.06
	ghostOutline.SurfaceTransparency = 1
	ghostOutline.Adornee = ghostPart
	ghostOutline.Parent = ghostPart

	BuildController.SetActiveBlock("plank")
	BuildController.SetBuildMode(true)
end

function BuildController.Start(): ()
	RunService.RenderStepped:Connect(_updateGhostPreview)

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.B then
			BuildController.SetBuildMode(not isBuildModeEnabled)
			return
		end

		local slotIndex = HOTBAR_KEY_MAP[input.KeyCode]
		if slotIndex then
			local blockId = Constants.HOTBAR_BLOCKS[slotIndex]
			if blockId then
				BuildController.SetActiveBlock(blockId :: BlockId)
			end
			return
		end

		if not isBuildModeEnabled then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if currentPlaceGrid and currentCanPlace then
				BuildController.RequestPlace(currentPlaceGrid)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.X then
			if currentRemoveGrid then
				BuildController.RequestRemove(currentRemoveGrid)
			end
		end
	end)
end

return BuildController
