--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local ResourceNodes = require(Shared.Config.ResourceNodes)
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

local Server = ServerScriptService:WaitForChild("Server")
local AtmosphereService = require(Server.Services.AtmosphereService)
local InventoryService = require(Server.Services.InventoryService)
local RoleService = require(Server.Services.RoleService)

type ResourceNodeKind = GameTypes.ResourceNodeKind
type ResourceNodeConfig = GameTypes.ResourceNodeConfig

type NodeRuntime = {
	id: string,
	kind: ResourceNodeKind,
	config: ResourceNodeConfig,
	origin: Vector3,
	health: number,
	depleted: boolean,
	model: Model,
}

local BASE_GATHER_DAMAGE = 10
local GATHER_REACH_STUDS = 16
local GATHER_COOLDOWN_SEC = 0.32

local SPAWN_LAYOUT: { { kind: ResourceNodeKind, x: number, z: number } } = {
	-- Voxel Pine Trees
	{ kind = "tree", x = -28, z = -22 },
	{ kind = "tree", x = -40, z = 6 },
	{ kind = "tree", x = -22, z = 34 },
	{ kind = "tree", x = 24, z = -32 },
	{ kind = "tree", x = 42, z = -8 },
	{ kind = "tree", x = 30, z = 28 },
	{ kind = "tree", x = 6, z = -44 },
	{ kind = "tree", x = -6, z = 46 },

	-- Voxel Stone Boulders
	{ kind = "stone_rock", x = -18, z = -34 },
	{ kind = "stone_rock", x = 34, z = 12 },
	{ kind = "stone_rock", x = -34, z = 22 },
	{ kind = "stone_rock", x = 16, z = 38 },

	-- Voxel Iron Ore Veins
	{ kind = "iron_vein", x = 46, z = 22 },
	{ kind = "iron_vein", x = -46, z = -12 },
	{ kind = "iron_vein", x = 12, z = -52 },

	-- Voxel Wild Berry & Herb Bushes
	{ kind = "herb_bush", x = -20, z = 14 },
	{ kind = "herb_bush", x = 20, z = -14 },
	{ kind = "herb_bush", x = 22, z = 18 },
	{ kind = "herb_bush", x = -26, z = -6 },
	{ kind = "herb_bush", x = 4, z = 28 },
}

local WorldService = {}
local nodesFolder: Folder
local nodesById: { [string]: NodeRuntime } = {}
local lastGatherByPlayer: { [Player]: number } = {}

local function _makeVoxelCube(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = color
	part.Material = material
	part.Parent = parent
	return part
end

local function _buildVoxelNodeModel(id: string, kind: ResourceNodeKind, basePos: Vector3): Model
	local model = Instance.new("Model")
	model.Name = id

	local primary: Part

	if kind == "tree" then
		-- Voxel trunk (2x8x2) + 3 stepped voxel leaf tiers
		primary = _makeVoxelCube(
			model,
			"Trunk",
			Vector3.new(2, 8, 2),
			basePos + Vector3.new(0, 4, 0),
			Color3.fromRGB(115, 74, 44),
			Enum.Material.Wood
		)
		_makeVoxelCube(
			model,
			"LeavesBottom",
			Vector3.new(8, 3, 8),
			basePos + Vector3.new(0, 8.5, 0),
			Color3.fromRGB(58, 128, 62),
			Enum.Material.SmoothPlastic
		)
		_makeVoxelCube(
			model,
			"LeavesMid",
			Vector3.new(6, 3, 6),
			basePos + Vector3.new(0, 11.5, 0),
			Color3.fromRGB(70, 148, 72),
			Enum.Material.SmoothPlastic
		)
		_makeVoxelCube(
			model,
			"LeavesTop",
			Vector3.new(3, 3, 3),
			basePos + Vector3.new(0, 14.5, 0),
			Color3.fromRGB(86, 168, 84),
			Enum.Material.SmoothPlastic
		)
	elseif kind == "stone_rock" then
		primary = _makeVoxelCube(
			model,
			"RockBase",
			Vector3.new(6, 3, 6),
			basePos + Vector3.new(0, 1.5, 0),
			Color3.fromRGB(132, 136, 142),
			Enum.Material.Slate
		)
		_makeVoxelCube(
			model,
			"RockTop",
			Vector3.new(4, 2, 4),
			basePos + Vector3.new(0.5, 4, -0.5),
			Color3.fromRGB(148, 152, 158),
			Enum.Material.Slate
		)
	elseif kind == "iron_vein" then
		primary = _makeVoxelCube(
			model,
			"OreBase",
			Vector3.new(6, 4, 6),
			basePos + Vector3.new(0, 2, 0),
			Color3.fromRGB(98, 102, 110),
			Enum.Material.Slate
		)
		_makeVoxelCube(
			model,
			"OreChunkA",
			Vector3.new(2, 2, 2),
			basePos + Vector3.new(2.2, 2.5, 1.2),
			Color3.fromRGB(196, 142, 92),
			Enum.Material.Metal
		)
		_makeVoxelCube(
			model,
			"OreChunkB",
			Vector3.new(2, 2, 2),
			basePos + Vector3.new(-2, 3.2, -1.5),
			Color3.fromRGB(205, 155, 105),
			Enum.Material.Metal
		)
		_makeVoxelCube(
			model,
			"OreTop",
			Vector3.new(3, 2, 3),
			basePos + Vector3.new(0, 5, 0),
			Color3.fromRGB(110, 114, 122),
			Enum.Material.Slate
		)
	else
		-- Voxel Herb & Berry Bush
		primary = _makeVoxelCube(
			model,
			"BushBase",
			Vector3.new(4, 3, 4),
			basePos + Vector3.new(0, 1.5, 0),
			Color3.fromRGB(64, 152, 74),
			Enum.Material.SmoothPlastic
		)
		_makeVoxelCube(
			model,
			"BushTop",
			Vector3.new(2.5, 1.5, 2.5),
			basePos + Vector3.new(0, 3.5, 0),
			Color3.fromRGB(82, 178, 88),
			Enum.Material.SmoothPlastic
		)
		_makeVoxelCube(
			model,
			"BerryA",
			Vector3.new(0.8, 0.8, 0.8),
			basePos + Vector3.new(1.8, 2.1, 0.6),
			Color3.fromRGB(220, 58, 88),
			Enum.Material.SmoothPlastic
		)
		_makeVoxelCube(
			model,
			"BerryB",
			Vector3.new(0.8, 0.8, 0.8),
			basePos + Vector3.new(-1.7, 1.8, -0.8),
			Color3.fromRGB(220, 58, 88),
			Enum.Material.SmoothPlastic
		)
		_makeVoxelCube(
			model,
			"BerryC",
			Vector3.new(0.8, 0.8, 0.8),
			basePos + Vector3.new(0.4, 2.6, -1.8),
			Color3.fromRGB(220, 58, 88),
			Enum.Material.SmoothPlastic
		)
	end

	model.PrimaryPart = primary
	model:SetAttribute("NodeId", id)
	model:SetAttribute("NodeKind", kind)
	model.Parent = nodesFolder
	return model
end

local function _setNodeVisible(model: Model, visible: boolean): ()
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if visible then 0 else 1
			descendant.CanCollide = visible
			descendant.CanQuery = visible
		end
	end
end

local function _syncNodeAttributes(node: NodeRuntime): ()
	node.model:SetAttribute("Health", node.health)
	node.model:SetAttribute("MaxHealth", node.config.maxHealth)
	node.model:SetAttribute("Depleted", node.depleted)
end

local function _spawnInitialNodes(): ()
	for index, entry in ipairs(SPAWN_LAYOUT) do
		local config = ResourceNodes[entry.kind]
		local id = string.format("Node_%s_%d", entry.kind, index)
		local basePos = Vector3.new(entry.x, 0, entry.z)
		local model = _buildVoxelNodeModel(id, entry.kind, basePos)

		local runtime: NodeRuntime = {
			id = id,
			kind = entry.kind,
			config = config,
			origin = basePos,
			health = config.maxHealth,
			depleted = false,
			model = model,
		}
		_syncNodeAttributes(runtime)
		nodesById[id] = runtime
	end
end

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

function WorldService.Init(): ()
	local existing = Workspace:FindFirstChild("ResourceNodes")
	if existing and existing:IsA("Folder") then
		nodesFolder = existing
	else
		local folder = Instance.new("Folder")
		folder.Name = "ResourceNodes"
		folder.Parent = Workspace
		nodesFolder = folder
	end
end

local function _styleStarterMeadowAndRuins(): ()
	-- Tint starter Baseplate to lush Dawnlands voxel meadow grass
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Color = Color3.fromRGB(92, 148, 76)
		baseplate.Material = Enum.Material.SmoothPlastic
	end

	if Workspace:FindFirstChild("AncientRuins") then
		return
	end

	local ruins = Instance.new("Folder")
	ruins.Name = "AncientRuins"
	ruins.Parent = Workspace

	local shrineCenter = Vector3.new(0, 0, -18)
	local stoneMid = Color3.fromRGB(134, 140, 148)
	local stoneDark = Color3.fromRGB(102, 108, 118)
	local mossGreen = Color3.fromRGB(74, 134, 68)

	-- Stepped voxel shrine plinth
	_makeVoxelCube(
		ruins,
		"PlinthBase",
		Vector3.new(16, 1, 16),
		shrineCenter + Vector3.new(0, 0.5, 0),
		stoneDark,
		Enum.Material.Slate
	)
	_makeVoxelCube(
		ruins,
		"PlinthTop",
		Vector3.new(12, 1, 12),
		shrineCenter + Vector3.new(0, 1.5, 0),
		stoneMid,
		Enum.Material.Slate
	)

	-- 4 weathered & broken voxel ruin pillars with mossy accents
	local pillarData = {
		{ offset = Vector3.new(-5.5, 0, -5.5), height = 10 },
		{ offset = Vector3.new(5.5, 0, -5.5), height = 8 },
		{ offset = Vector3.new(-5.5, 0, 5.5), height = 6 },
		{ offset = Vector3.new(5.5, 0, 5.5), height = 11 },
	}
	for index, info in ipairs(pillarData) do
		local base = shrineCenter + info.offset + Vector3.new(0, 2, 0)
		_makeVoxelCube(
			ruins,
			"Pillar_" .. tostring(index),
			Vector3.new(2, info.height, 2),
			base + Vector3.new(0, info.height * 0.5, 0),
			stoneMid,
			Enum.Material.Slate
		)
		_makeVoxelCube(
			ruins,
			"PillarMoss_" .. tostring(index),
			Vector3.new(2.2, 0.8, 2.2),
			base + Vector3.new(0, info.height + 0.4, 0),
			mossGreen,
			Enum.Material.SmoothPlastic
		)
	end

	-- Central glowing Ancient Voxel Rune Crystal
	local altar = _makeVoxelCube(
		ruins,
		"AltarPedestal",
		Vector3.new(3, 2, 3),
		shrineCenter + Vector3.new(0, 3, 0),
		stoneDark,
		Enum.Material.Slate
	)
	local rune = _makeVoxelCube(
		ruins,
		"AncientRune",
		Vector3.new(1.6, 1.6, 1.6),
		altar.Position + Vector3.new(0, 2.6, 0),
		Color3.fromRGB(85, 225, 255),
		Enum.Material.Neon
	)
	rune.Orientation = Vector3.new(35, 45, 0)

	local runeLight = Instance.new("PointLight")
	runeLight.Color = Color3.fromRGB(95, 225, 255)
	runeLight.Brightness = 2.0
	runeLight.Range = 24
	runeLight.Parent = rune

	-- Cobblestone voxel stepping path from spawn toward the ruins
	for stepIdx = 1, 4 do
		_makeVoxelCube(
			ruins,
			"PathStone_" .. tostring(stepIdx),
			Vector3.new(4, 0.3, 2.5),
			Vector3.new(0, 0.15, -3 - (stepIdx * 3.2)),
			if stepIdx % 2 == 0 then stoneMid else stoneDark,
			Enum.Material.Slate
		)
	end

	-- Starter Ancient Campfire beside the ruin clearing for warm night refuge
	AtmosphereService.SpawnCampfireAt(Vector3.new(10, 0, -10), 0)
end

function WorldService.Start(): ()
	_styleStarterMeadowAndRuins()
	_spawnInitialNodes()

	local gatherRemote = Remotes.GetEvent("GatherNode")
	local toastRemote = Remotes.GetEvent("ToastNotification")

	gatherRemote.OnServerEvent:Connect(function(player: Player, rawNodeId: unknown)
		if typeof(rawNodeId) ~= "string" then
			return
		end

		local now = os.clock()
		local lastGather = lastGatherByPlayer[player] or 0
		if now - lastGather < GATHER_COOLDOWN_SEC then
			return
		end

		local node = nodesById[rawNodeId]
		if not node or node.depleted then
			return
		end

		local origin = _getPlayerOrigin(player)
		if not origin then
			return
		end

		local flatDist = Vector3.new(origin.X - node.origin.X, 0, origin.Z - node.origin.Z).Magnitude
		if flatDist > GATHER_REACH_STUDS then
			return
		end

		lastGatherByPlayer[player] = now

		local role = RoleService.GetPlayerRole(player)
		local damage = BASE_GATHER_DAMAGE
		if node.config.gatherAction == "mine" then
			damage = math.round(BASE_GATHER_DAMAGE * role.perks.miningSpeedMultiplier)
		end

		node.health = math.max(0, node.health - damage)
		_syncNodeAttributes(node)

		if node.health > 0 then
			return
		end

		-- Depleted: calculate role-adjusted yield and award resources
		node.depleted = true
		_syncNodeAttributes(node)
		_setNodeVisible(node.model, false)

		local yieldMultiplier = if node.config.gatherAction == "forage" then role.perks.forageYieldMultiplier else 1.0
		local primaryCount = math.max(1, math.round(node.config.baseYield * yieldMultiplier))
		local addedPrimary = InventoryService.AddItem(player, node.config.dropItemId, primaryCount)
		local primaryName = Items[node.config.dropItemId].displayName

		local toastParts = { string.format("+%d %s", addedPrimary, primaryName) }

		if node.config.bonusItemId and node.config.bonusYield then
			local bonusCount = math.max(1, math.round(node.config.bonusYield * yieldMultiplier))
			local addedBonus = InventoryService.AddItem(player, node.config.bonusItemId, bonusCount)
			local bonusName = Items[node.config.bonusItemId].displayName
			table.insert(toastParts, string.format("+%d %s", addedBonus, bonusName))
		end

		toastRemote:FireClient(player, "Gathered " .. table.concat(toastParts, ", "), Color3.fromRGB(135, 235, 165))

		task.delay(node.config.respawnSeconds, function()
			node.health = node.config.maxHealth
			node.depleted = false
			_syncNodeAttributes(node)
			_setNodeVisible(node.model, true)
		end)
	end)
end

return WorldService
