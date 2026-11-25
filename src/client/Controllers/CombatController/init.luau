--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)
local Remotes = require(Shared.Network.Remotes)

local CombatController = {}
local localPlayer = Players.LocalPlayer
local lastSwingTime = 0

local function _spawnSlashVfx(root: BasePart, forward: Vector3): ()
	local slash = Instance.new("Part")
	slash.Name = "VoxelSlashVfx"
	slash.Size = Vector3.new(4.2, 0.35, 1.4)
	slash.Anchored = true
	slash.CanCollide = false
	slash.CanQuery = false
	slash.CanTouch = false
	slash.Material = Enum.Material.Neon
	slash.Color = Color3.fromRGB(255, 240, 175)
	slash.Transparency = 0.2
	slash.CFrame = CFrame.lookAt(root.Position + (forward * 3.5), root.Position + (forward * 8))
		* CFrame.Angles(0, 0, math.rad(-22))
	slash.Parent = Workspace

	local tween = TweenService:Create(slash, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(5.6, 0.12, 2.2),
		Transparency = 1,
	})
	tween:Play()
	task.delay(0.18, function()
		slash:Destroy()
	end)
end

local function _spawnDamageNumber(worldPos: Vector3, amount: number, isBoosted: boolean): ()
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = worldPos
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Parent = Workspace

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 90, 0, 32)
	gui.AlwaysOnTop = true
	gui.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = string.format("-%d", amount)
	label.TextColor3 = if isBoosted then Color3.fromRGB(255, 206, 75) else Color3.fromRGB(255, 248, 240)
	label.TextStrokeTransparency = 0.2
	label.TextSize = if isBoosted then 20 else 17
	label.Parent = gui

	local rise = TweenService:Create(
		anchor,
		TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = worldPos + Vector3.new(0, 3.2, 0) }
	)
	rise:Play()

	task.delay(0.68, function()
		anchor:Destroy()
	end)
end

local function _attemptMeleeAttack(): ()
	local now = os.clock()
	if now - lastSwingTime < Constants.MELEE_COOLDOWN_SEC then
		return
	end

	local staminaAttr = localPlayer:GetAttribute("CurrentStamina")
	if typeof(staminaAttr) == "number" and staminaAttr < Constants.MELEE_STAMINA_COST then
		return
	end

	local character = localPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return
	end

	local forward = root.CFrame.LookVector
	local camera = Workspace.CurrentCamera
	if camera then
		local flatLook = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
		if flatLook.Magnitude > 0.01 then
			forward = flatLook.Unit
		end
	end

	lastSwingTime = now
	_spawnSlashVfx(root, forward)
	Remotes.GetEvent("RequestAttack"):FireServer(forward)
end

function CombatController.Init(): ()
	-- Reserved for dependency setup.
end

function CombatController.Start(): ()
	Remotes.GetEvent("CombatFeedback").OnClientEvent
		:Connect(function(hitPos: unknown, damage: unknown, isBoosted: unknown)
			if typeof(hitPos) == "Vector3" and typeof(damage) == "number" then
				_spawnDamageNumber(hitPos, damage, isBoosted == true)
			end
		end)

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.F then
			_attemptMeleeAttack()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			local buildOn = localPlayer:GetAttribute("BuildModeEnabled")
			if buildOn == false then
				_attemptMeleeAttack()
			end
		end
	end)
end

return CombatController
