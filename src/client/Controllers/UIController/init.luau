--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Blocks = require(Shared.Config.Blocks)
local Constants = require(Shared.Config.Constants)
local Roles = require(Shared.Config.Roles)
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

type BlockId = GameTypes.BlockId
type RoleId = GameTypes.RoleId
type RoleDefinition = GameTypes.RoleDefinition
type SurvivalState = GameTypes.SurvivalState

local ROLE_ORDER: { RoleId } = { "architect", "blacksmith", "hunter", "alchemist" }

local UIController = {}
local localPlayer = Players.LocalPlayer

local healthFill: Frame
local staminaFill: Frame
local hungerFill: Frame
local roleBadgeLabel: TextLabel
local roleAccentStrip: Frame
local buildModeLabel: TextLabel
local roleModal: Frame
local controlsPanel: Frame
local hotbarStrokes: { [BlockId]: UIStroke } = {}

local function _addCorner(parent: GuiObject, radius: number): ()
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function _createStatBar(parent: Instance, labelText: string, barColor: Color3, order: number): Frame
	local container = Instance.new("Frame")
	container.Name = labelText .. "Bar"
	container.Size = UDim2.new(1, 0, 0, 22)
	container.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
	container.BackgroundTransparency = 0.2
	container.LayoutOrder = order
	container.Parent = parent
	_addCorner(container, 6)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = barColor
	fill.BorderSizePixel = 0
	fill.Parent = container
	_addCorner(fill, 6)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -12, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(245, 248, 255)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 2
	label.Parent = container

	return fill
end

local function _refreshRoleDisplay(): ()
	local attr = localPlayer:GetAttribute("RoleId")
	local roleId: RoleId = if typeof(attr) == "string" and (Roles :: { [string]: RoleDefinition })[attr]
		then attr :: RoleId
		else Constants.DEFAULT_ROLE :: RoleId
	local def = Roles[roleId]
	roleBadgeLabel.Text = string.format("ROLE: %s  [R]", string.upper(def.displayName))
	roleAccentStrip.BackgroundColor3 = def.accentColor
end

local function _refreshHotbarSelection(): ()
	local activeAttr = localPlayer:GetAttribute("ActiveBlockId")
	local buildAttr = localPlayer:GetAttribute("BuildModeEnabled")
	local isBuildOn = if typeof(buildAttr) == "boolean" then buildAttr else true

	buildModeLabel.Text = if isBuildOn then "BUILD MODE: ON  [B]" else "BUILD MODE: OFF  [B]"
	buildModeLabel.TextColor3 = if isBuildOn then Color3.fromRGB(115, 240, 150) else Color3.fromRGB(220, 130, 130)

	for blockId, stroke in pairs(hotbarStrokes) do
		local isSelected = activeAttr == blockId
		stroke.Color = if isSelected then Color3.fromRGB(255, 230, 120) else Color3.fromRGB(70, 76, 92)
		stroke.Thickness = if isSelected then 3 else 1.5
	end
end

local function _buildHud(): ()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VoxelRealmsHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = playerGui

	-- Top-Left: Role Badge button
	local roleButton = Instance.new("TextButton")
	roleButton.Name = "RoleBadge"
	roleButton.Size = UDim2.new(0, 230, 0, 40)
	roleButton.Position = UDim2.new(0, 16, 0, 16)
	roleButton.BackgroundColor3 = Color3.fromRGB(22, 25, 33)
	roleButton.BackgroundTransparency = 0.15
	roleButton.Text = ""
	roleButton.AutoButtonColor = true
	roleButton.Parent = screenGui
	_addCorner(roleButton, 8)

	roleAccentStrip = Instance.new("Frame")
	roleAccentStrip.Size = UDim2.new(0, 6, 1, -10)
	roleAccentStrip.Position = UDim2.new(0, 6, 0, 5)
	roleAccentStrip.BorderSizePixel = 0
	roleAccentStrip.Parent = roleButton
	_addCorner(roleAccentStrip, 3)

	roleBadgeLabel = Instance.new("TextLabel")
	roleBadgeLabel.Size = UDim2.new(1, -24, 1, 0)
	roleBadgeLabel.Position = UDim2.new(0, 20, 0, 0)
	roleBadgeLabel.BackgroundTransparency = 1
	roleBadgeLabel.Font = Enum.Font.GothamBold
	roleBadgeLabel.TextColor3 = Color3.fromRGB(242, 245, 252)
	roleBadgeLabel.TextSize = 14
	roleBadgeLabel.TextXAlignment = Enum.TextXAlignment.Left
	roleBadgeLabel.Parent = roleButton

	-- Bottom-Left: Survival Bars (HP, Stamina, Hunger)
	local survivalFrame = Instance.new("Frame")
	survivalFrame.Name = "SurvivalBars"
	survivalFrame.Size = UDim2.new(0, 240, 0, 82)
	survivalFrame.Position = UDim2.new(0, 16, 1, -98)
	survivalFrame.BackgroundTransparency = 1
	survivalFrame.Parent = screenGui

	local survivalLayout = Instance.new("UIListLayout")
	survivalLayout.Padding = UDim.new(0, 6)
	survivalLayout.SortOrder = Enum.SortOrder.LayoutOrder
	survivalLayout.Parent = survivalFrame

	healthFill = _createStatBar(survivalFrame, "HEALTH", Color3.fromRGB(215, 70, 75), 1)
	staminaFill = _createStatBar(survivalFrame, "STAMINA", Color3.fromRGB(70, 185, 115), 2)
	hungerFill = _createStatBar(survivalFrame, "HUNGER", Color3.fromRGB(225, 160, 60), 3)

	-- Bottom-Center: Voxel Hotbar
	local hotbarWrapper = Instance.new("Frame")
	hotbarWrapper.Name = "HotbarWrapper"
	hotbarWrapper.Size = UDim2.new(0, 340, 0, 86)
	hotbarWrapper.Position = UDim2.new(0.5, -170, 1, -102)
	hotbarWrapper.BackgroundTransparency = 1
	hotbarWrapper.Parent = screenGui

	buildModeLabel = Instance.new("TextLabel")
	buildModeLabel.Size = UDim2.new(1, 0, 0, 18)
	buildModeLabel.BackgroundTransparency = 1
	buildModeLabel.Font = Enum.Font.GothamBold
	buildModeLabel.TextSize = 12
	buildModeLabel.Text = "BUILD MODE: ON  [B]"
	buildModeLabel.Parent = hotbarWrapper

	local slotsFrame = Instance.new("Frame")
	slotsFrame.Size = UDim2.new(1, 0, 0, 62)
	slotsFrame.Position = UDim2.new(0, 0, 0, 22)
	slotsFrame.BackgroundTransparency = 1
	slotsFrame.Parent = hotbarWrapper

	local slotsLayout = Instance.new("UIListLayout")
	slotsLayout.FillDirection = Enum.FillDirection.Horizontal
	slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	slotsLayout.Padding = UDim.new(0, 8)
	slotsLayout.Parent = slotsFrame

	for index, rawBlockId in ipairs(Constants.HOTBAR_BLOCKS) do
		local blockId = rawBlockId :: BlockId
		local def = Blocks[blockId]

		local slot = Instance.new("Frame")
		slot.Name = "Slot_" .. blockId
		slot.Size = UDim2.new(0, 60, 0, 60)
		slot.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
		slot.BackgroundTransparency = 0.15
		slot.Parent = slotsFrame
		_addCorner(slot, 8)

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(70, 76, 92)
		stroke.Thickness = 1.5
		stroke.Parent = slot
		hotbarStrokes[blockId] = stroke

		local swatch = Instance.new("Frame")
		swatch.Size = UDim2.new(0, 28, 0, 28)
		swatch.Position = UDim2.new(0.5, -14, 0, 10)
		swatch.BackgroundColor3 = def.color
		swatch.BorderSizePixel = 0
		swatch.Parent = slot
		_addCorner(swatch, 5)

		local keyTag = Instance.new("TextLabel")
		keyTag.Size = UDim2.new(0, 16, 0, 16)
		keyTag.Position = UDim2.new(0, 4, 0, 2)
		keyTag.BackgroundTransparency = 1
		keyTag.Font = Enum.Font.GothamBold
		keyTag.Text = tostring(index)
		keyTag.TextColor3 = Color3.fromRGB(205, 212, 226)
		keyTag.TextSize = 11
		keyTag.Parent = slot

		local nameTag = Instance.new("TextLabel")
		nameTag.Size = UDim2.new(1, -4, 0, 16)
		nameTag.Position = UDim2.new(0, 2, 1, -18)
		nameTag.BackgroundTransparency = 1
		nameTag.Font = Enum.Font.GothamMedium
		nameTag.Text = string.upper(blockId)
		nameTag.TextColor3 = Color3.fromRGB(220, 226, 238)
		nameTag.TextSize = 9
		nameTag.Parent = slot
	end

	-- Top-Right: Compact Controls Guide
	controlsPanel = Instance.new("Frame")
	controlsPanel.Name = "ControlsPanel"
	controlsPanel.Size = UDim2.new(0, 215, 0, 146)
	controlsPanel.Position = UDim2.new(1, -231, 0, 16)
	controlsPanel.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
	controlsPanel.BackgroundTransparency = 0.22
	controlsPanel.Parent = screenGui
	_addCorner(controlsPanel, 8)

	local controlsText = Instance.new("TextLabel")
	controlsText.Size = UDim2.new(1, -16, 1, -12)
	controlsText.Position = UDim2.new(0, 8, 0, 6)
	controlsText.BackgroundTransparency = 1
	controlsText.Font = Enum.Font.GothamMedium
	controlsText.TextColor3 = Color3.fromRGB(218, 225, 238)
	controlsText.TextSize = 12
	controlsText.TextXAlignment = Enum.TextXAlignment.Left
	controlsText.TextYAlignment = Enum.TextYAlignment.Top
	controlsText.Text = table.concat({
		"CONTROLS  [H] Hide",
		"[V] 1st / 3rd Person",
		"[B] Toggle Build Mode",
		"[1-5] Select Block",
		"[LMB / RMB] Place / Break",
		"[Shift] Sprint  |  [Q] Dodge",
		"[R] Switch Role",
	}, "\n")
	controlsText.Parent = controlsPanel

	-- Center Modal: Role Selector
	roleModal = Instance.new("Frame")
	roleModal.Name = "RoleModal"
	roleModal.Size = UDim2.new(0, 520, 0, 340)
	roleModal.Position = UDim2.new(0.5, -260, 0.5, -170)
	roleModal.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
	roleModal.BackgroundTransparency = 0.08
	roleModal.Visible = false
	roleModal.Parent = screenGui
	_addCorner(roleModal, 12)

	local modalTitle = Instance.new("TextLabel")
	modalTitle.Size = UDim2.new(1, -24, 0, 38)
	modalTitle.Position = UDim2.new(0, 12, 0, 10)
	modalTitle.BackgroundTransparency = 1
	modalTitle.Font = Enum.Font.GothamBold
	modalTitle.Text = "CHOOSE YOUR ROLE  (Press R to Close)"
	modalTitle.TextColor3 = Color3.fromRGB(245, 248, 255)
	modalTitle.TextSize = 16
	modalTitle.Parent = roleModal

	local cardsHolder = Instance.new("Frame")
	cardsHolder.Size = UDim2.new(1, -28, 1, -64)
	cardsHolder.Position = UDim2.new(0, 14, 0, 52)
	cardsHolder.BackgroundTransparency = 1
	cardsHolder.Parent = roleModal

	local cardsGrid = Instance.new("UIGridLayout")
	cardsGrid.CellSize = UDim2.new(0.48, 0, 0, 126)
	cardsGrid.CellPadding = UDim2.new(0.04, 0, 0, 12)
	cardsGrid.Parent = cardsHolder

	for _, roleId in ipairs(ROLE_ORDER) do
		local def = Roles[roleId]
		local card = Instance.new("TextButton")
		card.Name = "RoleCard_" .. roleId
		card.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
		card.Text = ""
		card.AutoButtonColor = true
		card.Parent = cardsHolder
		_addCorner(card, 10)

		local topBar = Instance.new("Frame")
		topBar.Size = UDim2.new(1, 0, 0, 6)
		topBar.BackgroundColor3 = def.accentColor
		topBar.BorderSizePixel = 0
		topBar.Parent = card
		_addCorner(topBar, 4)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -16, 0, 26)
		title.Position = UDim2.new(0, 10, 0, 12)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.Text = def.displayName
		title.TextColor3 = Color3.fromRGB(250, 250, 255)
		title.TextSize = 15
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = card

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -20, 1, -46)
		desc.Position = UDim2.new(0, 10, 0, 40)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.Gotham
		desc.Text = def.summary
		desc.TextColor3 = Color3.fromRGB(195, 204, 222)
		desc.TextSize = 12
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.Parent = card

		card.MouseButton1Click:Connect(function()
			Remotes.GetEvent("SelectRole"):FireServer(roleId)
			roleModal.Visible = false
		end)
	end

	roleButton.MouseButton1Click:Connect(function()
		roleModal.Visible = not roleModal.Visible
	end)
end

function UIController.Init(): ()
	_buildHud()
	_refreshRoleDisplay()
	_refreshHotbarSelection()
end

function UIController.Start(): ()
	localPlayer:GetAttributeChangedSignal("RoleId"):Connect(_refreshRoleDisplay)
	localPlayer:GetAttributeChangedSignal("ActiveBlockId"):Connect(_refreshHotbarSelection)
	localPlayer:GetAttributeChangedSignal("BuildModeEnabled"):Connect(_refreshHotbarSelection)

	Remotes.GetEvent("SurvivalStateChanged").OnClientEvent:Connect(function(state: SurvivalState)
		localPlayer:SetAttribute("CurrentStamina", state.stamina)

		local healthRatio = if state.maxHealth > 0 then math.clamp(state.health / state.maxHealth, 0, 1) else 0
		local staminaRatio = if state.maxStamina > 0 then math.clamp(state.stamina / state.maxStamina, 0, 1) else 0
		local hungerRatio = if state.maxHunger > 0 then math.clamp(state.hunger / state.maxHunger, 0, 1) else 0

		healthFill.Size = UDim2.new(healthRatio, 0, 1, 0)
		staminaFill.Size = UDim2.new(staminaRatio, 0, 1, 0)
		hungerFill.Size = UDim2.new(hungerRatio, 0, 1, 0)
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.R then
			roleModal.Visible = not roleModal.Visible
		elseif input.KeyCode == Enum.KeyCode.H then
			controlsPanel.Visible = not controlsPanel.Visible
		end
	end)
end

return UIController
