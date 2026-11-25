--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ResourceNodes = require(Shared.Config.ResourceNodes)
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

type ResourceNodeKind = GameTypes.ResourceNodeKind
type ResourceNodeConfig = GameTypes.ResourceNodeConfig

local TARGET_RANGE_STUDS = 15

local GatherController = {}
local localPlayer = Players.LocalPlayer
local currentTargetModel: Model? = nil
local currentTargetNodeId: string? = nil

local highlight: Highlight
local promptGui: BillboardGui
local promptLabel: TextLabel

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

local function _findNearestNode(origin: Vector3): (Model?, string?)
	local nodesFolder = Workspace:FindFirstChild("ResourceNodes")
	if not nodesFolder then
		return nil, nil
	end

	local bestModel: Model? = nil
	local bestId: string? = nil
	local bestDist = TARGET_RANGE_STUDS

	for _, child in ipairs(nodesFolder:GetChildren()) do
		if child:IsA("Model") and child.PrimaryPart then
			local depleted = child:GetAttribute("Depleted")
			local nodeId = child:GetAttribute("NodeId")
			if depleted ~= true and typeof(nodeId) == "string" then
				local nodePos = child.PrimaryPart.Position
				local flatDist = Vector3.new(origin.X - nodePos.X, 0, origin.Z - nodePos.Z).Magnitude
				if flatDist <= bestDist then
					bestDist = flatDist
					bestModel = child
					bestId = nodeId
				end
			end
		end
	end

	return bestModel, bestId
end

local function _updateTarget(): ()
	local origin = _getPlayerOrigin()
	if not origin then
		currentTargetModel = nil
		currentTargetNodeId = nil
		highlight.Adornee = nil
		promptGui.Adornee = nil
		promptGui.Enabled = false
		return
	end

	local model, nodeId = _findNearestNode(origin)
	currentTargetModel = model
	currentTargetNodeId = nodeId

	if not model or not model.PrimaryPart then
		highlight.Adornee = nil
		promptGui.Adornee = nil
		promptGui.Enabled = false
		return
	end

	local kindAttr = model:GetAttribute("NodeKind")
	local config: ResourceNodeConfig? = if typeof(kindAttr) == "string"
		then (ResourceNodes :: { [string]: ResourceNodeConfig })[kindAttr]
		else nil

	local hp = model:GetAttribute("Health")
	local maxHp = model:GetAttribute("MaxHealth")
	local hpNum = if typeof(hp) == "number" then hp else 0
	local maxHpNum = if typeof(maxHp) == "number" then maxHp else 1

	if config then
		promptLabel.Text = string.format("[E] %s %s (%d/%d)", config.actionLabel, config.displayName, hpNum, maxHpNum)
	else
		promptLabel.Text = "[E] Gather Resource"
	end

	highlight.Adornee = model
	promptGui.Adornee = model.PrimaryPart
	promptGui.Enabled = true
end

local function _attemptGather(): ()
	if currentTargetNodeId then
		Remotes.GetEvent("GatherNode"):FireServer(currentTargetNodeId)
	end
end

function GatherController.Init(): ()
	highlight = Instance.new("Highlight")
	highlight.Name = "ResourceGatherHighlight"
	highlight.FillColor = Color3.fromRGB(255, 240, 150)
	highlight.FillTransparency = 0.78
	highlight.OutlineColor = Color3.fromRGB(255, 232, 120)
	highlight.OutlineTransparency = 0.1
	highlight.Parent = Workspace

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	promptGui = Instance.new("BillboardGui")
	promptGui.Name = "GatherPromptBillboard"
	promptGui.Size = UDim2.new(0, 260, 0, 34)
	promptGui.StudsOffset = Vector3.new(0, 5.5, 0)
	promptGui.AlwaysOnTop = true
	promptGui.Enabled = false
	promptGui.Parent = playerGui

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	bg.BackgroundTransparency = 0.18
	bg.Parent = promptGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = bg

	promptLabel = Instance.new("TextLabel")
	promptLabel.Size = UDim2.new(1, -12, 1, 0)
	promptLabel.Position = UDim2.new(0, 6, 0, 0)
	promptLabel.BackgroundTransparency = 1
	promptLabel.Font = Enum.Font.GothamBold
	promptLabel.TextColor3 = Color3.fromRGB(245, 248, 255)
	promptLabel.TextSize = 13
	promptLabel.Parent = bg
end

function GatherController.Start(): ()
	RunService.RenderStepped:Connect(_updateTarget)

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.E then
			_attemptGather()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			local buildOn = localPlayer:GetAttribute("BuildModeEnabled")
			if buildOn == false and currentTargetModel then
				_attemptGather()
			end
		end
	end)
end

return GatherController
