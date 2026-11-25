--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)

local Server = ServerScriptService:WaitForChild("Server")
local SurvivalService = require(Server.Services.SurvivalService)

type CampfireRecord = {
	model: Model,
	position: Vector3,
	light: PointLight,
	ownerUserId: number,
}

local AtmosphereService = {}
local campfiresFolder: Folder
local activeCampfires: { CampfireRecord } = {}
local clockTime = Constants.START_CLOCK_TIME
local lastAuraTick = 0
local lastClockBroadcast = 0

local function _makeVoxelPart(
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

local function _getDayPhase(hour: number): string
	if hour >= 5.5 and hour < 8.0 then
		return "Dawn"
	elseif hour >= 8.0 and hour < 17.5 then
		return "Day"
	elseif hour >= 17.5 and hour < 20.0 then
		return "Dusk"
	else
		return "Night"
	end
end

local function _updateLightingForHour(hour: number): ()
	Lighting.ClockTime = hour

	-- Smooth Dawnlands-inspired ambient & brightness curve
	local dayFactor = 0.0
	if hour >= 6.0 and hour <= 18.0 then
		local t = (hour - 6.0) / 12.0
		dayFactor = math.sin(t * math.pi)
	end

	local isTwilight = (hour >= 5.0 and hour < 8.0) or (hour >= 17.0 and hour < 20.5)
	Lighting.Brightness = 0.85 + (dayFactor * 1.95)

	if isTwilight then
		Lighting.OutdoorAmbient = Color3.fromRGB(145, 112, 108)
		Lighting.Ambient = Color3.fromRGB(78, 62, 68)
		Lighting.ColorShift_Top = Color3.fromRGB(255, 178, 122)
	elseif dayFactor > 0.2 then
		Lighting.OutdoorAmbient = Color3.fromRGB(132, 148, 168)
		Lighting.Ambient = Color3.fromRGB(74, 82, 92)
		Lighting.ColorShift_Top = Color3.fromRGB(255, 246, 224)
	else
		Lighting.OutdoorAmbient = Color3.fromRGB(48, 60, 88)
		Lighting.Ambient = Color3.fromRGB(28, 34, 52)
		Lighting.ColorShift_Top = Color3.fromRGB(110, 138, 198)
	end
end

local function _ensurePostEffects(): ()
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.28
		atmosphere.Offset = 0.15
		atmosphere.Glare = 0.18
		atmosphere.Haze = 1.2
		atmosphere.Color = Color3.fromRGB(192, 214, 238)
		atmosphere.Decay = Color3.fromRGB(112, 138, 170)
		atmosphere.Parent = Lighting
	end

	if not Lighting:FindFirstChildOfClass("BloomEffect") then
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.35
		bloom.Size = 18
		bloom.Threshold = 1.1
		bloom.Parent = Lighting
	end
end

function AtmosphereService.SpawnCampfireAt(basePos: Vector3, ownerUserId: number): Model
	local model = Instance.new("Model")
	model.Name = string.format("VoxelCampfire_%d", ownerUserId)

	-- Ash base (scaled 1m = 4 studs -> ~3.2 stud footprint)
	local core = _makeVoxelPart(
		model,
		"AshBed",
		Vector3.new(3.0, 0.3, 3.0),
		basePos + Vector3.new(0, 0.15, 0),
		Color3.fromRGB(46, 42, 44),
		Enum.Material.Slate
	)

	-- Ring of 8 staggered voxel cobble stones
	local stoneOffsets = {
		Vector3.new(1.6, 0.36, 0),
		Vector3.new(-1.6, 0.36, 0),
		Vector3.new(0, 0.36, 1.6),
		Vector3.new(0, 0.36, -1.6),
		Vector3.new(1.2, 0.32, 1.2),
		Vector3.new(-1.2, 0.32, 1.2),
		Vector3.new(1.2, 0.32, -1.2),
		Vector3.new(-1.2, 0.32, -1.2),
	}
	for index, offset in ipairs(stoneOffsets) do
		local shade = if index % 2 == 0 then Color3.fromRGB(136, 142, 150) else Color3.fromRGB(112, 118, 126)
		_makeVoxelPart(
			model,
			"Stone_" .. tostring(index),
			Vector3.new(0.85, 0.72, 0.85),
			basePos + offset,
			shade,
			Enum.Material.Slate
		)
	end

	-- Crossed voxel firewood logs
	_makeVoxelPart(
		model,
		"LogA",
		Vector3.new(2.4, 0.52, 0.52),
		basePos + Vector3.new(0, 0.56, 0),
		Color3.fromRGB(122, 80, 46),
		Enum.Material.Wood
	)
	_makeVoxelPart(
		model,
		"LogB",
		Vector3.new(0.52, 0.52, 2.4),
		basePos + Vector3.new(0, 0.72, 0),
		Color3.fromRGB(98, 62, 36),
		Enum.Material.Wood
	)

	-- Glowing stepped voxel flame cubes
	local flameBase = _makeVoxelPart(
		model,
		"FlameRed",
		Vector3.new(1.15, 0.9, 1.15),
		basePos + Vector3.new(0, 1.2, 0),
		Color3.fromRGB(224, 68, 42),
		Enum.Material.Neon
	)
	flameBase.CanCollide = false

	local flameMid = _makeVoxelPart(
		model,
		"FlameOrange",
		Vector3.new(0.82, 0.85, 0.82),
		basePos + Vector3.new(0.1, 1.85, -0.08),
		Color3.fromRGB(248, 142, 40),
		Enum.Material.Neon
	)
	flameMid.CanCollide = false

	local flameTop = _makeVoxelPart(
		model,
		"FlameYellow",
		Vector3.new(0.46, 0.7, 0.46),
		basePos + Vector3.new(-0.06, 2.45, 0.06),
		Color3.fromRGB(255, 224, 88),
		Enum.Material.Neon
	)
	flameTop.CanCollide = false

	-- Warm flickering point light
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 168, 86)
	light.Brightness = 2.6
	light.Range = 28
	light.Shadows = true
	light.Parent = flameMid

	-- Subtle rising voxel ember particles
	local embers = Instance.new("ParticleEmitter")
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 210, 90), Color3.fromRGB(235, 85, 35))
	embers.Size = NumberSequence.new(0.22, 0.05)
	embers.Lifetime = NumberRange.new(0.9, 1.8)
	embers.Rate = 7
	embers.Speed = NumberRange.new(2.0, 4.2)
	embers.SpreadAngle = Vector2.new(18, 18)
	embers.LightEmission = 0.85
	embers.Parent = flameMid

	model.PrimaryPart = core
	model.Parent = campfiresFolder

	table.insert(activeCampfires, {
		model = model,
		position = basePos,
		light = light,
		ownerUserId = ownerUserId,
	})

	return model
end

function AtmosphereService.PlaceCampfireForPlayer(player: Player): (boolean, string)
	local character = player.Character
	if not character then
		return false, "Character not ready."
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false, "Character root missing."
	end

	-- Enforce per-player campfire cap cleanly
	local ownedCount = 0
	for _, record in ipairs(activeCampfires) do
		if record.ownerUserId == player.UserId then
			ownedCount += 1
		end
	end

	if ownedCount >= Constants.MAX_CAMPFIRES_PER_PLAYER then
		return false, string.format("Campfire limit reached (%d max).", Constants.MAX_CAMPFIRES_PER_PLAYER)
	end

	local flatLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if flatLook.Magnitude < 0.01 then
		flatLook = Vector3.new(0, 0, -1)
	else
		flatLook = flatLook.Unit
	end

	local targetXZ = root.Position + (flatLook * 6)
	local groundY = 0

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local ray =
		Workspace:Raycast(Vector3.new(targetXZ.X, root.Position.Y + 6, targetXZ.Z), Vector3.new(0, -30, 0), params)
	if ray then
		groundY = ray.Position.Y
	end

	AtmosphereService.SpawnCampfireAt(Vector3.new(targetXZ.X, groundY, targetXZ.Z), player.UserId)
	return true, "Placed glowing Voxel Campfire!"
end

function AtmosphereService.Init(): ()
	local existing = Workspace:FindFirstChild("Campfires")
	if existing and existing:IsA("Folder") then
		campfiresFolder = existing
	else
		local folder = Instance.new("Folder")
		folder.Name = "Campfires"
		folder.Parent = Workspace
		campfiresFolder = folder
	end

	_ensurePostEffects()
	_updateLightingForHour(clockTime)
	Workspace:SetAttribute("ClockTime", clockTime)
	Workspace:SetAttribute("DayPhase", _getDayPhase(clockTime))
end

function AtmosphereService.Start(): ()
	local hoursPerSecond = 24.0 / Constants.DAY_LENGTH_SECONDS

	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()

		clockTime = (clockTime + (hoursPerSecond * dt)) % 24.0
		_updateLightingForHour(clockTime)

		if now - lastClockBroadcast >= 0.5 then
			lastClockBroadcast = now
			Workspace:SetAttribute("ClockTime", clockTime)
			Workspace:SetAttribute("DayPhase", _getDayPhase(clockTime))
		end

		-- Gentle campfire light flicker
		local flicker = 2.4 + (math.sin(now * 9.5) * 0.25) + (math.cos(now * 14.3) * 0.15)
		for _, record in ipairs(activeCampfires) do
			record.light.Brightness = flicker
		end

		-- Campfire warmth & rest aura
		if now - lastAuraTick >= Constants.CAMPFIRE_TICK_SECONDS then
			lastAuraTick = now
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				if root and root:IsA("BasePart") then
					local nearFire = false
					for _, record in ipairs(activeCampfires) do
						if (root.Position - record.position).Magnitude <= Constants.CAMPFIRE_AURA_RADIUS then
							nearFire = true
							break
						end
					end

					if nearFire then
						SurvivalService.ModifyStats(
							player,
							Constants.CAMPFIRE_HEALTH_PER_TICK,
							Constants.CAMPFIRE_STAMINA_PER_TICK,
							Constants.CAMPFIRE_HUNGER_PER_TICK
						)
					end
				end
			end
		end
	end)
end

return AtmosphereService
