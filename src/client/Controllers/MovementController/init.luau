--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)
local Remotes = require(Shared.Network.Remotes)

local MovementController = {}
local localPlayer = Players.LocalPlayer
local lastDodgeTime = 0
local isSprinting = false

local function _performDodge(): ()
	local now = os.clock()
	if now - lastDodgeTime < Constants.DODGE_COOLDOWN_SEC then
		return
	end

	local character = localPlayer.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid then
		return
	end

	local staminaAttr = localPlayer:GetAttribute("CurrentStamina")
	if typeof(staminaAttr) == "number" and staminaAttr < Constants.DODGE_STAMINA_COST then
		return
	end

	lastDodgeTime = now
	Remotes.GetEvent("RequestDodge"):FireServer()

	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude < 0.1 then
		local camera = Workspace.CurrentCamera
		if camera then
			local flatLook = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
			if flatLook.Magnitude > 0.01 then
				moveDir = flatLook.Unit
			end
		end
	else
		moveDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
	end

	if moveDir.Magnitude < 0.01 then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "DodgeAttachment"
	attachment.Parent = root

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "DodgeVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	velocity.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	velocity.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	velocity.PlaneVelocity = Vector2.new(moveDir.X * Constants.DODGE_SPEED, moveDir.Z * Constants.DODGE_SPEED)
	velocity.MaxForce = 1e5
	velocity.Parent = root

	task.delay(Constants.DODGE_DURATION_SEC, function()
		velocity:Destroy()
		attachment:Destroy()
	end)
end

local function _setSprinting(enabled: boolean): ()
	if isSprinting == enabled then
		return
	end
	isSprinting = enabled
	Remotes.GetEvent("SetSprinting"):FireServer(enabled)
end

function MovementController.Init(): ()
	-- Reserved for dependency setup.
end

function MovementController.Start(): ()
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftShift then
			_setSprinting(true)
		elseif input.KeyCode == Enum.KeyCode.Q then
			_performDodge()
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			_setSprinting(false)
		end
	end)
end

return MovementController
