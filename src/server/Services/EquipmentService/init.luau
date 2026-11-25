--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tools = require(Shared.Config.Tools)
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

local Server = ServerScriptService:WaitForChild("Server")
local RoleService = require(Server.Services.RoleService)

type ToolId = GameTypes.ToolId
type ToolDefinition = GameTypes.ToolDefinition

local DEFAULT_TOOL: ToolId = "axe"

local EquipmentService = {}
local equippedTools: { [Player]: ToolId } = {}

local function _makeWeldedVoxel(
	parent: Instance,
	anchorPart: BasePart,
	name: string,
	size: Vector3,
	localCFrame: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = anchorPart.CFrame * localCFrame
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = color
	part.Material = material
	part.Parent = parent

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchorPart
	weld.Part1 = part
	weld.Parent = part

	return part
end

local function _findTorso(character: Model): BasePart?
	local upper = character:FindFirstChild("UpperTorso")
	if upper and upper:IsA("BasePart") then
		return upper
	end
	local torso = character:FindFirstChild("Torso")
	if torso and torso:IsA("BasePart") then
		return torso
	end
	return nil
end

local function _findRightHand(character: Model): BasePart?
	local hand = character:FindFirstChild("RightHand")
	if hand and hand:IsA("BasePart") then
		return hand
	end
	local arm = character:FindFirstChild("Right Arm")
	if arm and arm:IsA("BasePart") then
		return arm
	end
	return nil
end

local function _rebuildRoleOutfit(player: Player): ()
	local character = player.Character
	if not character then
		return
	end

	local existing = character:FindFirstChild("VoxelRoleGear")
	if existing then
		existing:Destroy()
	end

	local torso = _findTorso(character)
	local head = character:FindFirstChild("Head")
	if not torso then
		return
	end

	local role = RoleService.GetPlayerRole(player)
	local gearFolder = Instance.new("Folder")
	gearFolder.Name = "VoxelRoleGear"
	gearFolder.Parent = character

	-- Role-colored voxel adventurer backpack + gold clasp
	_makeWeldedVoxel(
		gearFolder,
		torso,
		"VoxelBackpack",
		Vector3.new(1.3, 1.4, 0.55),
		CFrame.new(0, 0.05, 0.72),
		Color3.fromRGB(108, 72, 44),
		Enum.Material.SmoothPlastic
	)
	_makeWeldedVoxel(
		gearFolder,
		torso,
		"BackpackBanner",
		Vector3.new(0.85, 0.9, 0.14),
		CFrame.new(0, 0.05, 1.02),
		role.accentColor,
		Enum.Material.SmoothPlastic
	)
	_makeWeldedVoxel(
		gearFolder,
		torso,
		"BackpackClasp",
		Vector3.new(0.4, 0.2, 0.16),
		CFrame.new(0, 0.45, 1.03),
		Color3.fromRGB(230, 188, 78),
		Enum.Material.Metal
	)

	-- Role-colored voxel shoulder pauldrons
	_makeWeldedVoxel(
		gearFolder,
		torso,
		"PauldronL",
		Vector3.new(0.62, 0.42, 1.12),
		CFrame.new(-1.18, 0.62, 0),
		role.accentColor,
		Enum.Material.SmoothPlastic
	)
	_makeWeldedVoxel(
		gearFolder,
		torso,
		"PauldronR",
		Vector3.new(0.62, 0.42, 1.12),
		CFrame.new(1.18, 0.62, 0),
		role.accentColor,
		Enum.Material.SmoothPlastic
	)

	-- Overhead multiplayer Roleplay Nameplate
	if head and head:IsA("BasePart") then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "RoleNameplate"
		billboard.Size = UDim2.new(0, 180, 0, 42)
		billboard.StudsOffset = Vector3.new(0, 2.2, 0)
		billboard.AlwaysOnTop = false
		billboard.MaxDistance = 75
		billboard.Parent = gearFolder
		billboard.Adornee = head

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, 20)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Text = player.DisplayName
		nameLabel.TextColor3 = Color3.fromRGB(248, 250, 255)
		nameLabel.TextStrokeTransparency = 0.35
		nameLabel.TextSize = 14
		nameLabel.Parent = billboard

		local rolePill = Instance.new("TextLabel")
		rolePill.Size = UDim2.new(0.76, 0, 0, 18)
		rolePill.Position = UDim2.new(0.12, 0, 0, 22)
		rolePill.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
		rolePill.BackgroundTransparency = 0.2
		rolePill.Font = Enum.Font.GothamBold
		rolePill.Text = string.upper(role.displayName)
		rolePill.TextColor3 = role.accentColor
		rolePill.TextSize = 11
		rolePill.Parent = billboard

		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(0, 6)
		pillCorner.Parent = rolePill
	end
end

local function _rebuildHeldTool(player: Player): ()
	local character = player.Character
	if not character then
		return
	end

	local existing = character:FindFirstChild("VoxelEquippedTool")
	if existing then
		existing:Destroy()
	end

	local hand = _findRightHand(character)
	if not hand then
		return
	end

	local toolId = equippedTools[player] or DEFAULT_TOOL
	local toolFolder = Instance.new("Folder")
	toolFolder.Name = "VoxelEquippedTool"
	toolFolder.Parent = character

	-- Grip aligned forward & slightly upright from right hand
	local isR6Arm = hand.Name == "Right Arm"
	local baseGrip = if isR6Arm
		then CFrame.new(0, -1.0, -0.35) * CFrame.Angles(math.rad(-75), 0, 0)
		else CFrame.new(0, -0.15, -0.35) * CFrame.Angles(math.rad(-75), 0, 0)

	local leather = Color3.fromRGB(108, 72, 44)
	local wood = Color3.fromRGB(178, 134, 84)
	local steelLight = Color3.fromRGB(206, 214, 224)
	local steelDark = Color3.fromRGB(142, 152, 166)
	local stoneMid = Color3.fromRGB(144, 150, 158)
	local gold = Color3.fromRGB(228, 184, 72)

	if toolId == "axe" then
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"Grip",
			Vector3.new(0.28, 0.7, 0.28),
			baseGrip,
			leather,
			Enum.Material.SmoothPlastic
		)
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"Shaft",
			Vector3.new(0.24, 1.8, 0.24),
			baseGrip * CFrame.new(0, 1.15, 0),
			wood,
			Enum.Material.Wood
		)
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"BladeBase",
			Vector3.new(0.22, 0.6, 0.45),
			baseGrip * CFrame.new(0, 1.8, -0.3),
			steelDark,
			Enum.Material.Metal
		)
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"BladeEdge",
			Vector3.new(0.14, 0.95, 0.45),
			baseGrip * CFrame.new(0, 1.75, -0.68),
			steelLight,
			Enum.Material.Metal
		)
	elseif toolId == "pickaxe" then
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"Grip",
			Vector3.new(0.28, 0.7, 0.28),
			baseGrip,
			leather,
			Enum.Material.SmoothPlastic
		)
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"Shaft",
			Vector3.new(0.24, 1.9, 0.24),
			baseGrip * CFrame.new(0, 1.2, 0),
			wood,
			Enum.Material.Wood
		)
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"HeadHub",
			Vector3.new(0.36, 0.42, 0.44),
			baseGrip * CFrame.new(0, 2.05, 0),
			stoneMid,
			Enum.Material.Slate
		)
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"PickFront",
			Vector3.new(0.26, 0.32, 0.85),
			baseGrip * CFrame.new(0, 1.98, -0.58) * CFrame.Angles(math.rad(-14), 0, 0),
			steelLight,
			Enum.Material.Slate
		)
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"PickBack",
			Vector3.new(0.26, 0.32, 0.85),
			baseGrip * CFrame.new(0, 1.98, 0.58) * CFrame.Angles(math.rad(14), 0, 0),
			steelLight,
			Enum.Material.Slate
		)
	else
		-- Voxel Broadsword
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"Hilt",
			Vector3.new(0.26, 0.75, 0.26),
			baseGrip,
			leather,
			Enum.Material.SmoothPlastic
		)
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"Pommel",
			Vector3.new(0.34, 0.26, 0.34),
			baseGrip * CFrame.new(0, -0.45, 0),
			gold,
			Enum.Material.Metal
		)
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"Guard",
			Vector3.new(0.34, 0.24, 1.15),
			baseGrip * CFrame.new(0, 0.45, 0),
			gold,
			Enum.Material.Metal
		)
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"BladeMain",
			Vector3.new(0.16, 2.1, 0.46),
			baseGrip * CFrame.new(0, 1.6, 0),
			steelLight,
			Enum.Material.Metal
		)
		_makeWeldedVoxel(
			toolFolder,
			hand,
			"BladeTip",
			Vector3.new(0.14, 0.45, 0.28),
			baseGrip * CFrame.new(0, 2.85, 0),
			steelLight,
			Enum.Material.Metal
		)
	end
end

local function _bindPlayer(player: Player): ()
	equippedTools[player] = DEFAULT_TOOL
	player:SetAttribute("EquippedToolId", DEFAULT_TOOL)

	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		if player:IsDescendantOf(Players) then
			_rebuildRoleOutfit(player)
			_rebuildHeldTool(player)
		end
	end)

	player:GetAttributeChangedSignal("RoleId"):Connect(function()
		_rebuildRoleOutfit(player)
	end)

	if player.Character then
		task.defer(function()
			_rebuildRoleOutfit(player)
			_rebuildHeldTool(player)
		end)
	end
end

function EquipmentService.GetEquippedTool(player: Player): ToolDefinition
	local toolId = equippedTools[player] or DEFAULT_TOOL
	return Tools[toolId]
end

function EquipmentService.GetToolBonus(player: Player, specialty: "chop" | "mine" | "combat"): number
	local tool = EquipmentService.GetEquippedTool(player)
	if tool.specialty == specialty then
		return tool.bonusMultiplier
	end
	return 1.0
end

function EquipmentService.Init(): ()
	-- Reserved for dependency setup.
end

function EquipmentService.Start(): ()
	local equipToolRemote = Remotes.GetEvent("EquipTool")

	Players.PlayerAdded:Connect(_bindPlayer)

	Players.PlayerRemoving:Connect(function(player: Player)
		equippedTools[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if not equippedTools[player] then
			_bindPlayer(player)
		end
	end

	equipToolRemote.OnServerEvent:Connect(function(player: Player, rawToolId: unknown)
		if typeof(rawToolId) ~= "string" then
			return
		end

		local def = (Tools :: { [string]: ToolDefinition })[rawToolId]
		if not def then
			return
		end

		equippedTools[player] = def.id
		player:SetAttribute("EquippedToolId", def.id)
		_rebuildHeldTool(player)
	end)
end

return EquipmentService
