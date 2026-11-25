--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Blocks = require(Shared.Config.Blocks)
local Constants = require(Shared.Config.Constants)
local Items = require(Shared.Config.Items)
local Recipes = require(Shared.Config.Recipes)
local Roles = require(Shared.Config.Roles)
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

type BlockId = GameTypes.BlockId
type ItemId = GameTypes.ItemId
type InventoryMap = GameTypes.InventoryMap
type RoleId = GameTypes.RoleId
type RoleDefinition = GameTypes.RoleDefinition
type SurvivalState = GameTypes.SurvivalState

local ROLE_ORDER: { RoleId } = { "architect", "blacksmith", "hunter", "alchemist" }
local ITEM_DISPLAY_ORDER: { ItemId } = {
	"wood",
	"stone",
	"iron_ore",
	"herb",
	"berry",
	"plank_block",
	"timber_block",
	"stone_block",
	"healing_tonic",
	"campfire_kit",
}

local UIController = {}
local localPlayer = Players.LocalPlayer
local currentInventory: InventoryMap = {}

local healthFill: Frame
local staminaFill: Frame
local hungerFill: Frame
local roleBadgeLabel: TextLabel
local roleAccentStrip: Frame
local clockLabel: TextLabel
local buildModeLabel: TextLabel
local roleModal: Frame
local inventoryModal: Frame
local inventoryList: ScrollingFrame
local craftingModal: Frame
local craftingList: ScrollingFrame
local controlsPanel: Frame
local toastContainer: Frame
local hotbarStrokes: { [BlockId]: UIStroke } = {}

local function _addCorner(parent: GuiObject, radius: number): ()
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function _getActiveRoleId(): RoleId
	local attr = localPlayer:GetAttribute("RoleId")
	if typeof(attr) == "string" and (Roles :: { [string]: RoleDefinition })[attr] then
		return attr :: RoleId
	end
	return Constants.DEFAULT_ROLE :: RoleId
end

local function _closeAllModals(): ()
	roleModal.Visible = false
	inventoryModal.Visible = false
	craftingModal.Visible = false
end

local function _toggleModal(target: Frame): ()
	local willOpen = not target.Visible
	_closeAllModals()
	target.Visible = willOpen
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

local function _clearListChildren(container: ScrollingFrame): ()
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function _refreshInventoryModal(): ()
	_clearListChildren(inventoryList)

	local rowCount = 0
	for _, itemId in ipairs(ITEM_DISPLAY_ORDER) do
		local count = currentInventory[itemId] or 0
		if count > 0 then
			rowCount += 1
			local def = Items[itemId]

			local row = Instance.new("Frame")
			row.Name = "ItemRow_" .. itemId
			row.Size = UDim2.new(1, -8, 0, 56)
			row.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
			row.LayoutOrder = rowCount
			row.Parent = inventoryList
			_addCorner(row, 8)

			local swatch = Instance.new("Frame")
			swatch.Size = UDim2.new(0, 32, 0, 32)
			swatch.Position = UDim2.new(0, 12, 0.5, -16)
			swatch.BackgroundColor3 = def.accentColor
			swatch.BorderSizePixel = 0
			swatch.Parent = row
			_addCorner(swatch, 6)

			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -150, 0, 22)
			title.Position = UDim2.new(0, 54, 0, 6)
			title.BackgroundTransparency = 1
			title.Font = Enum.Font.GothamBold
			title.Text = string.format("%s  ×%d", def.displayName, count)
			title.TextColor3 = Color3.fromRGB(248, 250, 255)
			title.TextSize = 14
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Parent = row

			local desc = Instance.new("TextLabel")
			desc.Size = UDim2.new(1, -150, 0, 24)
			desc.Position = UDim2.new(0, 54, 0, 28)
			desc.BackgroundTransparency = 1
			desc.Font = Enum.Font.Gotham
			desc.Text = def.description
			desc.TextColor3 = Color3.fromRGB(185, 195, 215)
			desc.TextSize = 11
			desc.TextTruncate = Enum.TextTruncate.AtEnd
			desc.TextXAlignment = Enum.TextXAlignment.Left
			desc.Parent = row

			if def.category == "consumable" or def.category == "placeable" then
				local useBtn = Instance.new("TextButton")
				useBtn.Size = UDim2.new(0, 74, 0, 30)
				useBtn.Position = UDim2.new(1, -86, 0.5, -15)
				useBtn.BackgroundColor3 = if def.category == "placeable"
					then Color3.fromRGB(225, 130, 52)
					else Color3.fromRGB(68, 175, 108)
				useBtn.Font = Enum.Font.GothamBold
				useBtn.Text = if def.category == "placeable" then "PLACE" else "USE"
				useBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				useBtn.TextSize = 12
				useBtn.Parent = row
				_addCorner(useBtn, 6)

				useBtn.MouseButton1Click:Connect(function()
					Remotes.GetEvent("UseItem"):FireServer(itemId)
					if def.category == "placeable" then
						_closeAllModals()
					end
				end)
			end
		end
	end

	if rowCount == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 48)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Font = Enum.Font.GothamMedium
		emptyLabel.Text = "Your pack is empty — press [E] near trees, rocks, or berry bushes to gather!"
		emptyLabel.TextColor3 = Color3.fromRGB(185, 195, 215)
		emptyLabel.TextSize = 13
		emptyLabel.TextWrapped = true
		emptyLabel.Parent = inventoryList
	end

	inventoryList.CanvasSize = UDim2.new(0, 0, 0, math.max(1, rowCount) * 64)
end

local function _refreshCraftingModal(): ()
	_clearListChildren(craftingList)

	local activeRoleId = _getActiveRoleId()

	for index, recipe in ipairs(Recipes) do
		local hasAllIngredients = true
		local ingredientParts: { string } = {}
		for itemId, needed in pairs(recipe.ingredients) do
			local owned = currentInventory[itemId] or 0
			if owned < needed then
				hasAllIngredients = false
			end
			local itemName = Items[itemId].displayName
			table.insert(ingredientParts, string.format("%s %d/%d", itemName, owned, needed))
		end

		local roleAllowed = if recipe.requiredRole then activeRoleId == recipe.requiredRole else true
		local canCraft = hasAllIngredients and roleAllowed

		local row = Instance.new("Frame")
		row.Name = "RecipeRow_" .. recipe.id
		row.Size = UDim2.new(1, -8, 0, 68)
		row.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
		row.LayoutOrder = index
		row.Parent = craftingList
		_addCorner(row, 8)

		local roleSuffix = ""
		if recipe.requiredRole then
			roleSuffix = string.format("  [%s Only]", Roles[recipe.requiredRole].displayName)
		end

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -110, 0, 22)
		title.Position = UDim2.new(0, 12, 0, 6)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.Text = recipe.displayName .. roleSuffix
		title.TextColor3 = if roleAllowed then Color3.fromRGB(248, 250, 255) else Color3.fromRGB(230, 150, 150)
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = row

		local reqLabel = Instance.new("TextLabel")
		reqLabel.Size = UDim2.new(1, -110, 0, 18)
		reqLabel.Position = UDim2.new(0, 12, 0, 28)
		reqLabel.BackgroundTransparency = 1
		reqLabel.Font = Enum.Font.GothamMedium
		reqLabel.Text = "Needs: " .. table.concat(ingredientParts, "  |  ")
		reqLabel.TextColor3 = if hasAllIngredients then Color3.fromRGB(130, 225, 160) else Color3.fromRGB(225, 175, 115)
		reqLabel.TextSize = 11
		reqLabel.TextXAlignment = Enum.TextXAlignment.Left
		reqLabel.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -110, 0, 18)
		desc.Position = UDim2.new(0, 12, 0, 46)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.Gotham
		desc.Text = recipe.description
		desc.TextColor3 = Color3.fromRGB(175, 186, 206)
		desc.TextSize = 11
		desc.TextTruncate = Enum.TextTruncate.AtEnd
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.Parent = row

		local craftBtn = Instance.new("TextButton")
		craftBtn.Size = UDim2.new(0, 82, 0, 34)
		craftBtn.Position = UDim2.new(1, -94, 0.5, -17)
		craftBtn.BackgroundColor3 = if canCraft then Color3.fromRGB(68, 160, 230) else Color3.fromRGB(64, 68, 82)
		craftBtn.Font = Enum.Font.GothamBold
		craftBtn.Text = if roleAllowed then "CRAFT" else "LOCKED"
		craftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		craftBtn.TextSize = 12
		craftBtn.Parent = row
		_addCorner(craftBtn, 6)

		craftBtn.MouseButton1Click:Connect(function()
			Remotes.GetEvent("CraftRecipe"):FireServer(recipe.id)
		end)
	end

	craftingList.CanvasSize = UDim2.new(0, 0, 0, #Recipes * 76)
end

local function _showToast(message: string, accentColor: Color3?): ()
	local banner = Instance.new("Frame")
	banner.Size = UDim2.new(1, 0, 0, 32)
	banner.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	banner.BackgroundTransparency = 0.12
	banner.Parent = toastContainer
	_addCorner(banner, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = message
	label.TextColor3 = accentColor or Color3.fromRGB(240, 245, 255)
	label.TextSize = 13
	label.Parent = banner

	task.delay(2.6, function()
		banner:Destroy()
	end)
end

local function _refreshRoleDisplay(): ()
	local def = Roles[_getActiveRoleId()]
	roleBadgeLabel.Text = string.format("ROLE: %s  [R]", string.upper(def.displayName))
	roleAccentStrip.BackgroundColor3 = def.accentColor
	_refreshCraftingModal()
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

local function _createModalFrame(
	parent: Instance,
	name: string,
	titleText: string,
	width: number,
	height: number
): (Frame, ScrollingFrame)
	local modal = Instance.new("Frame")
	modal.Name = name
	modal.Size = UDim2.new(0, width, 0, height)
	modal.Position = UDim2.new(0.5, -math.floor(width / 2), 0.5, -math.floor(height / 2))
	modal.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
	modal.BackgroundTransparency = 0.08
	modal.Visible = false
	modal.Parent = parent
	_addCorner(modal, 12)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 38)
	title.Position = UDim2.new(0, 12, 0, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = titleText
	title.TextColor3 = Color3.fromRGB(245, 248, 255)
	title.TextSize = 16
	title.Parent = modal

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -28, 1, -64)
	list.Position = UDim2.new(0, 14, 0, 52)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.Parent = modal

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	return modal, list
end

local function _buildHud(): ()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VoxelRealmsHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = playerGui

	-- Top-Center: Toast Notifications
	toastContainer = Instance.new("Frame")
	toastContainer.Name = "ToastContainer"
	toastContainer.Size = UDim2.new(0, 360, 0, 140)
	toastContainer.Position = UDim2.new(0.5, -180, 0, 16)
	toastContainer.BackgroundTransparency = 1
	toastContainer.Parent = screenGui

	local toastLayout = Instance.new("UIListLayout")
	toastLayout.Padding = UDim.new(0, 6)
	toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	toastLayout.Parent = toastContainer

	-- Top-Left: Role Badge button + Quick Inventory/Craft buttons
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

	local invQuickBtn = Instance.new("TextButton")
	invQuickBtn.Size = UDim2.new(0, 111, 0, 30)
	invQuickBtn.Position = UDim2.new(0, 16, 0, 62)
	invQuickBtn.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
	invQuickBtn.BackgroundTransparency = 0.15
	invQuickBtn.Font = Enum.Font.GothamBold
	invQuickBtn.Text = "PACK  [I]"
	invQuickBtn.TextColor3 = Color3.fromRGB(230, 236, 248)
	invQuickBtn.TextSize = 12
	invQuickBtn.Parent = screenGui
	_addCorner(invQuickBtn, 7)

	local craftQuickBtn = Instance.new("TextButton")
	craftQuickBtn.Size = UDim2.new(0, 111, 0, 30)
	craftQuickBtn.Position = UDim2.new(0, 135, 0, 62)
	craftQuickBtn.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
	craftQuickBtn.BackgroundTransparency = 0.15
	craftQuickBtn.Font = Enum.Font.GothamBold
	craftQuickBtn.Text = "CRAFT  [C]"
	craftQuickBtn.TextColor3 = Color3.fromRGB(230, 236, 248)
	craftQuickBtn.TextSize = 12
	craftQuickBtn.Parent = screenGui
	_addCorner(craftQuickBtn, 7)

	-- Top-Left: Day Phase & Clock Pill
	local clockFrame = Instance.new("Frame")
	clockFrame.Name = "ClockPill"
	clockFrame.Size = UDim2.new(0, 230, 0, 28)
	clockFrame.Position = UDim2.new(0, 16, 0, 98)
	clockFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	clockFrame.BackgroundTransparency = 0.2
	clockFrame.Parent = screenGui
	_addCorner(clockFrame, 7)

	clockLabel = Instance.new("TextLabel")
	clockLabel.Size = UDim2.new(1, -16, 1, 0)
	clockLabel.Position = UDim2.new(0, 8, 0, 0)
	clockLabel.BackgroundTransparency = 1
	clockLabel.Font = Enum.Font.GothamBold
	clockLabel.Text = "DAY  08:30"
	clockLabel.TextColor3 = Color3.fromRGB(250, 224, 145)
	clockLabel.TextSize = 12
	clockLabel.TextXAlignment = Enum.TextXAlignment.Left
	clockLabel.Parent = clockFrame

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
	controlsPanel.Size = UDim2.new(0, 225, 0, 184)
	controlsPanel.Position = UDim2.new(1, -241, 0, 16)
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
		"[E] Gather Resources",
		"[I] Inventory  |  [C] Craft",
		"[R] Switch Role",
		"[B] Toggle Build Mode",
		"[1-5] Select Block",
		"[LMB / RMB] Place / Break",
		"[Shift] Sprint  |  [Q] Dodge",
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

	-- Center Modals: Inventory & Crafting
	inventoryModal, inventoryList =
		_createModalFrame(screenGui, "InventoryModal", "SURVIVAL PACK  (Press I to Close)", 540, 380)
	craftingModal, craftingList =
		_createModalFrame(screenGui, "CraftingModal", "CRAFTING BENCH  (Press C to Close)", 580, 420)

	roleButton.MouseButton1Click:Connect(function()
		_toggleModal(roleModal)
	end)
	invQuickBtn.MouseButton1Click:Connect(function()
		_toggleModal(inventoryModal)
	end)
	craftQuickBtn.MouseButton1Click:Connect(function()
		_toggleModal(craftingModal)
	end)
end

local function _refreshClockDisplay(): ()
	local rawClock = Workspace:GetAttribute("ClockTime")
	local rawPhase = Workspace:GetAttribute("DayPhase")
	local hourFloat = if typeof(rawClock) == "number" then rawClock else Constants.START_CLOCK_TIME
	local phase = if typeof(rawPhase) == "string" then rawPhase else "Day"

	local hours = math.floor(hourFloat) % 24
	local minutes = math.floor((hourFloat - math.floor(hourFloat)) * 60)
	clockLabel.Text = string.format("%s  %02d:%02d", string.upper(phase), hours, minutes)

	if phase == "Dawn" or phase == "Dusk" then
		clockLabel.TextColor3 = Color3.fromRGB(255, 178, 112)
	elseif phase == "Night" then
		clockLabel.TextColor3 = Color3.fromRGB(150, 185, 255)
	else
		clockLabel.TextColor3 = Color3.fromRGB(252, 230, 142)
	end
end

function UIController.Init(): ()
	_buildHud()
	_refreshRoleDisplay()
	_refreshHotbarSelection()
	_refreshInventoryModal()
	_refreshCraftingModal()
	_refreshClockDisplay()
end

function UIController.Start(): ()
	localPlayer:GetAttributeChangedSignal("RoleId"):Connect(_refreshRoleDisplay)
	localPlayer:GetAttributeChangedSignal("ActiveBlockId"):Connect(_refreshHotbarSelection)
	localPlayer:GetAttributeChangedSignal("BuildModeEnabled"):Connect(_refreshHotbarSelection)
	Workspace:GetAttributeChangedSignal("ClockTime"):Connect(_refreshClockDisplay)
	Workspace:GetAttributeChangedSignal("DayPhase"):Connect(_refreshClockDisplay)

	Remotes.GetEvent("SurvivalStateChanged").OnClientEvent:Connect(function(state: SurvivalState)
		localPlayer:SetAttribute("CurrentStamina", state.stamina)

		local healthRatio = if state.maxHealth > 0 then math.clamp(state.health / state.maxHealth, 0, 1) else 0
		local staminaRatio = if state.maxStamina > 0 then math.clamp(state.stamina / state.maxStamina, 0, 1) else 0
		local hungerRatio = if state.maxHunger > 0 then math.clamp(state.hunger / state.maxHunger, 0, 1) else 0

		healthFill.Size = UDim2.new(healthRatio, 0, 1, 0)
		staminaFill.Size = UDim2.new(staminaRatio, 0, 1, 0)
		hungerFill.Size = UDim2.new(hungerRatio, 0, 1, 0)
	end)

	Remotes.GetEvent("InventoryUpdated").OnClientEvent:Connect(function(updated: InventoryMap)
		currentInventory = updated
		_refreshInventoryModal()
		_refreshCraftingModal()
	end)

	Remotes.GetEvent("ToastNotification").OnClientEvent:Connect(function(message: unknown, color: unknown)
		if typeof(message) ~= "string" then
			return
		end
		local resolvedColor = if typeof(color) == "Color3" then color :: Color3 else nil
		_showToast(message, resolvedColor)
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.R then
			_toggleModal(roleModal)
		elseif input.KeyCode == Enum.KeyCode.I then
			_toggleModal(inventoryModal)
		elseif input.KeyCode == Enum.KeyCode.C then
			_toggleModal(craftingModal)
		elseif input.KeyCode == Enum.KeyCode.H then
			controlsPanel.Visible = not controlsPanel.Visible
		elseif input.KeyCode == Enum.KeyCode.Escape then
			_closeAllModals()
		end
	end)
end

return UIController
