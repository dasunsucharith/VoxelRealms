--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)
local Creatures = require(Shared.Config.Creatures)
local Items = require(Shared.Config.Items)
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

local Server = ServerScriptService:WaitForChild("Server")
local InventoryService = require(Server.Services.InventoryService)
local SurvivalService = require(Server.Services.SurvivalService)

type CreatureKind = GameTypes.CreatureKind
type CreatureConfig = GameTypes.CreatureConfig

type CreatureRuntime = {
	id: string,
	kind: CreatureKind,
	config: CreatureConfig,
	homePos: Vector3,
	position: Vector3,
	yaw: number,
	health: number,
	alive: boolean,
	patrolAngle: number,
	lastAttackTime: number,
	model: Model,
	hpFill: Frame,
	hpBillboard: BillboardGui,
	parts: { Part },
	originalColors: { [Part]: Color3 },
}

local SPAWN_LAYOUT: { { kind: CreatureKind, x: number, z: number } } = {
	{ kind = "slime", x = -54, z = 18 },
	{ kind = "slime", x = 52, z = 24 },
	{ kind = "slime", x = 18, z = 58 },
	{ kind = "slime", x = -22, z = 56 },
	{ kind = "wolf", x = -58, z = -32 },
	{ kind = "wolf", x = 58, z = -28 },
	{ kind = "wolf", x = 0, z = -66 },
}

local CreatureService = {}
local creaturesFolder: Folder
local creaturesById: { [string]: CreatureRuntime } = {}

local function _makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	localOffset: Vector3,
	color: Color3,
	material: Enum.Material,
	transparency: number?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(localOffset)
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = color
	part.Material = material
	part.Transparency = transparency or 0
	part.Parent = parent
	return part
end

local function _buildCreatureModel(
	id: string,
	kind: CreatureKind,
	config: CreatureConfig
): (Model, { Part }, { [Part]: Color3 }, BillboardGui, Frame)
	local model = Instance.new("Model")
	model.Name = id

	local parts: { Part } = {}
	local originalColors: { [Part]: Color3 } = {}

	local function addPart(
		name: string,
		size: Vector3,
		offset: Vector3,
		color: Color3,
		material: Enum.Material,
		transparency: number?
	): Part
		local p = _makePart(model, name, size, offset, color, material, transparency)
		table.insert(parts, p)
		originalColors[p] = color
		return p
	end

	local rootPart: Part
	if kind == "slime" then
		rootPart = addPart(
			"BodyOuter",
			Vector3.new(3.2, 2.8, 3.2),
			Vector3.new(0, 1.4, 0),
			Color3.fromRGB(72, 206, 108),
			Enum.Material.SmoothPlastic,
			0.28
		)
		addPart(
			"BodyCore",
			Vector3.new(2.0, 1.8, 2.0),
			Vector3.new(0, 1.25, 0),
			Color3.fromRGB(48, 162, 78),
			Enum.Material.SmoothPlastic,
			0
		)
		addPart(
			"EyeL",
			Vector3.new(0.45, 0.45, 0.25),
			Vector3.new(-0.65, 1.6, -1.62),
			Color3.fromRGB(24, 28, 34),
			Enum.Material.SmoothPlastic,
			0
		)
		addPart(
			"EyeR",
			Vector3.new(0.45, 0.45, 0.25),
			Vector3.new(0.65, 1.6, -1.62),
			Color3.fromRGB(24, 28, 34),
			Enum.Material.SmoothPlastic,
			0
		)
		addPart(
			"Mouth",
			Vector3.new(0.6, 0.25, 0.2),
			Vector3.new(0, 1.05, -1.62),
			Color3.fromRGB(24, 28, 34),
			Enum.Material.SmoothPlastic,
			0
		)
	else
		-- Crisp Voxel Timber Wolf (-Z forward)
		local furMid = Color3.fromRGB(118, 122, 130)
		local furDark = Color3.fromRGB(78, 82, 92)
		local furBelly = Color3.fromRGB(182, 184, 188)

		rootPart =
			addPart("Torso", Vector3.new(2.2, 1.8, 4.0), Vector3.new(0, 2.2, 0), furMid, Enum.Material.SmoothPlastic, 0)
		addPart("Mane", Vector3.new(2.6, 2.1, 1.6), Vector3.new(0, 2.35, -1.2), furDark, Enum.Material.SmoothPlastic, 0)
		addPart("Belly", Vector3.new(1.8, 0.5, 3.2), Vector3.new(0, 1.3, 0.1), furBelly, Enum.Material.SmoothPlastic, 0)
		addPart("Head", Vector3.new(1.9, 1.7, 1.9), Vector3.new(0, 2.8, -2.55), furMid, Enum.Material.SmoothPlastic, 0)
		addPart(
			"Snout",
			Vector3.new(1.1, 0.9, 1.2),
			Vector3.new(0, 2.45, -3.75),
			furBelly,
			Enum.Material.SmoothPlastic,
			0
		)
		addPart(
			"Nose",
			Vector3.new(0.45, 0.35, 0.3),
			Vector3.new(0, 2.75, -4.35),
			Color3.fromRGB(30, 32, 36),
			Enum.Material.SmoothPlastic,
			0
		)
		addPart(
			"EarL",
			Vector3.new(0.45, 0.75, 0.4),
			Vector3.new(-0.6, 3.9, -2.2),
			furDark,
			Enum.Material.SmoothPlastic,
			0
		)
		addPart(
			"EarR",
			Vector3.new(0.45, 0.75, 0.4),
			Vector3.new(0.6, 3.9, -2.2),
			furDark,
			Enum.Material.SmoothPlastic,
			0
		)
		addPart(
			"EyeL",
			Vector3.new(0.32, 0.32, 0.2),
			Vector3.new(-0.55, 3.05, -3.52),
			Color3.fromRGB(255, 195, 65),
			Enum.Material.Neon,
			0
		)
		addPart(
			"EyeR",
			Vector3.new(0.32, 0.32, 0.2),
			Vector3.new(0.55, 3.05, -3.52),
			Color3.fromRGB(255, 195, 65),
			Enum.Material.Neon,
			0
		)
		addPart(
			"Tail",
			Vector3.new(0.75, 0.75, 2.2),
			Vector3.new(0, 2.55, 2.75),
			furDark,
			Enum.Material.SmoothPlastic,
			0
		)

		-- 4 voxel legs
		addPart(
			"LegFL",
			Vector3.new(0.65, 1.4, 0.65),
			Vector3.new(-0.7, 0.7, -1.35),
			furDark,
			Enum.Material.SmoothPlastic,
			0
		)
		addPart(
			"LegFR",
			Vector3.new(0.65, 1.4, 0.65),
			Vector3.new(0.7, 0.7, -1.35),
			furDark,
			Enum.Material.SmoothPlastic,
			0
		)
		addPart(
			"LegBL",
			Vector3.new(0.65, 1.4, 0.65),
			Vector3.new(-0.7, 0.7, 1.35),
			furDark,
			Enum.Material.SmoothPlastic,
			0
		)
		addPart(
			"LegBR",
			Vector3.new(0.65, 1.4, 0.65),
			Vector3.new(0.7, 0.7, 1.35),
			furDark,
			Enum.Material.SmoothPlastic,
			0
		)
	end

	-- Floating Name & HP Bar Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.new(0, 150, 0, 34)
	billboard.StudsOffset = Vector3.new(0, if kind == "wolf" then 3.2 else 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 55
	billboard.Parent = rootPart

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = config.displayName
	nameLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
	nameLabel.TextStrokeTransparency = 0.35
	nameLabel.TextSize = 12
	nameLabel.Parent = billboard

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -16, 0, 10)
	barBg.Position = UDim2.new(0, 8, 0, 18)
	barBg.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
	barBg.BorderSizePixel = 0
	barBg.Parent = billboard

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 4)
	barCorner.Parent = barBg

	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(220, 72, 72)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = hpFill

	model.PrimaryPart = rootPart
	model:SetAttribute("CreatureId", id)
	model:SetAttribute("CreatureKind", kind)
	model.Parent = creaturesFolder

	return model, parts, originalColors, billboard, hpFill
end

local function _setCreatureVisible(creature: CreatureRuntime, visible: boolean): ()
	creature.hpBillboard.Enabled = visible
	for _, part in ipairs(creature.parts) do
		if visible then
			part.Transparency = if creature.kind == "slime" and part.Name == "BodyOuter" then 0.28 else 0
		else
			part.Transparency = 1
		end
	end
end

local function _updateCreatureTransform(creature: CreatureRuntime, bounceY: number): ()
	local pivotHeight = if creature.kind == "wolf" then 2.2 else 1.4
	local targetCFrame = CFrame.new(creature.position + Vector3.new(0, pivotHeight + bounceY, 0))
		* CFrame.Angles(0, creature.yaw, 0)
	creature.model:PivotTo(targetCFrame)
end

local function _findNearestTarget(creature: CreatureRuntime): (Player?, Vector3?, number)
	local bestPlayer: Player? = nil
	local bestPos: Vector3? = nil
	local bestDist = creature.config.aggroRange

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
			local pos = root.Position
			-- Respect safe shrine sanctuary around spawn
			local shrineDist =
				Vector3.new(pos.X - Constants.SAFE_SHRINE_CENTER.X, 0, pos.Z - Constants.SAFE_SHRINE_CENTER.Z).Magnitude
			if shrineDist > Constants.SAFE_SHRINE_RADIUS then
				local dist = Vector3.new(pos.X - creature.position.X, 0, pos.Z - creature.position.Z).Magnitude
				if dist < bestDist then
					bestDist = dist
					bestPlayer = player
					bestPos = pos
				end
			end
		end
	end

	return bestPlayer, bestPos, bestDist
end

function CreatureService.FindCreaturesInArc(
	origin: Vector3,
	forward: Vector3,
	maxRange: number
): { { id: string, position: Vector3 } }
	local hits: { { id: string, position: Vector3 } } = {}
	local flatForward = Vector3.new(forward.X, 0, forward.Z)
	if flatForward.Magnitude < 0.01 then
		flatForward = Vector3.new(0, 0, -1)
	else
		flatForward = flatForward.Unit
	end

	for _, creature in pairs(creaturesById) do
		if creature.alive then
			local delta = Vector3.new(creature.position.X - origin.X, 0, creature.position.Z - origin.Z)
			local dist = delta.Magnitude
			if dist <= maxRange then
				local inFront = dist < 4.5 or delta.Unit:Dot(flatForward) > 0.2
				if inFront then
					table.insert(hits, {
						id = creature.id,
						position = creature.position + Vector3.new(0, 2.5, 0),
					})
				end
			end
		end
	end

	return hits
end

function CreatureService.DamageCreature(creatureId: string, damage: number, attacker: Player): (boolean, Vector3?)
	local creature = creaturesById[creatureId]
	if not creature or not creature.alive then
		return false, nil
	end

	creature.health = math.max(0, creature.health - damage)
	creature.hpFill.Size = UDim2.new(math.clamp(creature.health / creature.config.maxHealth, 0, 1), 0, 1, 0)

	-- Brief red hit flash
	for _, part in ipairs(creature.parts) do
		part.Color = Color3.fromRGB(255, 85, 85)
	end
	task.delay(0.12, function()
		if creature.alive then
			for _, part in ipairs(creature.parts) do
				part.Color = creature.originalColors[part]
			end
		end
	end)

	-- Small knockback away from attacker
	local attackerChar = attacker.Character
	local attackerRoot = if attackerChar then attackerChar:FindFirstChild("HumanoidRootPart") else nil
	if attackerRoot and attackerRoot:IsA("BasePart") then
		local push =
			Vector3.new(creature.position.X - attackerRoot.Position.X, 0, creature.position.Z - attackerRoot.Position.Z)
		if push.Magnitude > 0.01 then
			creature.position += push.Unit * 2.4
			_updateCreatureTransform(creature, 0.3)
		end
	end

	local hitPos = creature.position + Vector3.new(0, 2.5, 0)

	if creature.health <= 0 then
		creature.alive = false
		_setCreatureVisible(creature, false)

		local addedPrimary = InventoryService.AddItem(attacker, creature.config.dropItemId, creature.config.dropCount)
		local primaryName = Items[creature.config.dropItemId].displayName
		local dropParts = { string.format("+%d %s", addedPrimary, primaryName) }

		if creature.config.bonusItemId and creature.config.bonusCount then
			local addedBonus =
				InventoryService.AddItem(attacker, creature.config.bonusItemId, creature.config.bonusCount)
			local bonusName = Items[creature.config.bonusItemId].displayName
			table.insert(dropParts, string.format("+%d %s", addedBonus, bonusName))
		end

		Remotes.GetEvent("ToastNotification"):FireClient(
			attacker,
			string.format("Defeated %s! %s", creature.config.displayName, table.concat(dropParts, ", ")),
			Color3.fromRGB(255, 212, 108)
		)

		task.delay(creature.config.respawnSeconds, function()
			creature.position = creature.homePos
			creature.health = creature.config.maxHealth
			creature.hpFill.Size = UDim2.new(1, 0, 1, 0)
			for _, part in ipairs(creature.parts) do
				part.Color = creature.originalColors[part]
			end
			creature.alive = true
			_setCreatureVisible(creature, true)
			_updateCreatureTransform(creature, 0)
		end)
	end

	return true, hitPos
end

function CreatureService.Init(): ()
	local existing = Workspace:FindFirstChild("Creatures")
	if existing and existing:IsA("Folder") then
		creaturesFolder = existing
	else
		local folder = Instance.new("Folder")
		folder.Name = "Creatures"
		folder.Parent = Workspace
		creaturesFolder = folder
	end
end

function CreatureService.Start(): ()
	for index, entry in ipairs(SPAWN_LAYOUT) do
		local config = Creatures[entry.kind]
		local id = string.format("Creature_%s_%d", entry.kind, index)
		local home = Vector3.new(entry.x, 0, entry.z)
		local model, parts, originalColors, billboard, hpFill = _buildCreatureModel(id, entry.kind, config)

		local runtime: CreatureRuntime = {
			id = id,
			kind = entry.kind,
			config = config,
			homePos = home,
			position = home,
			yaw = index * 1.1,
			health = config.maxHealth,
			alive = true,
			patrolAngle = index * 1.4,
			lastAttackTime = 0,
			model = model,
			hpFill = hpFill,
			hpBillboard = billboard,
			parts = parts,
			originalColors = originalColors,
		}
		_updateCreatureTransform(runtime, 0)
		creaturesById[id] = runtime
	end

	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()

		for _, creature in pairs(creaturesById) do
			if creature.alive then
				local homeDist = (creature.position - creature.homePos).Magnitude
				local targetPlayer, targetPos, targetDist = _findNearestTarget(creature)

				local desiredPos: Vector3? = nil
				local speed = creature.config.moveSpeed

				if targetPlayer and targetPos and homeDist < creature.config.leashRange then
					if targetDist <= creature.config.attackRange then
						-- Melee attack player on cooldown
						if now - creature.lastAttackTime >= creature.config.attackCooldown then
							creature.lastAttackTime = now
							SurvivalService.ModifyStats(targetPlayer, -creature.config.damage, 0, 0)
							Remotes.GetEvent("ToastNotification"):FireClient(
								targetPlayer,
								string.format(
									"%s hit you for -%d HP!",
									creature.config.displayName,
									creature.config.damage
								),
								Color3.fromRGB(240, 95, 95)
							)
						end
					else
						desiredPos = Vector3.new(targetPos.X, 0, targetPos.Z)
					end
				else
					-- Calm circular patrol near home territory
					creature.patrolAngle += dt * 0.45
					local radius = if creature.kind == "wolf" then 10 else 6
					desiredPos = creature.homePos
						+ Vector3.new(
							math.cos(creature.patrolAngle) * radius,
							0,
							math.sin(creature.patrolAngle) * radius
						)
					speed = creature.config.moveSpeed * 0.45
				end

				local bounceY = 0
				if desiredPos then
					local delta = desiredPos - creature.position
					local dist = delta.Magnitude
					if dist > 0.25 then
						local dir = delta.Unit
						local step = math.min(dist, speed * dt)
						creature.position += dir * step
						creature.yaw = math.atan2(-dir.X, -dir.Z)
						bounceY = if creature.kind == "slime"
							then math.abs(math.sin(now * 6.5)) * 1.1
							else math.abs(math.sin(now * 10.5)) * 0.22
					end
				end

				_updateCreatureTransform(creature, bounceY)
			end
		end
	end)
end

return CreatureService
