--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

export type RemoteName =
	"SelectRole"
	| "RoleUpdated"
	| "PlaceVoxel"
	| "RemoveVoxel"
	| "SurvivalStateChanged"
	| "SetSprinting"
	| "RequestDodge"
	| "InventoryUpdated"
	| "GatherNode"
	| "CraftRecipe"
	| "UseItem"
	| "ToastNotification"
	| "RequestAttack"
	| "CombatFeedback"
	| "EquipTool"

local REMOTE_NAMES: { RemoteName } = {
	"SelectRole",
	"RoleUpdated",
	"PlaceVoxel",
	"RemoveVoxel",
	"SurvivalStateChanged",
	"SetSprinting",
	"RequestDodge",
	"InventoryUpdated",
	"GatherNode",
	"CraftRecipe",
	"UseItem",
	"ToastNotification",
	"RequestAttack",
	"CombatFeedback",
	"EquipTool",
}

local Remotes = {}
local remotesFolder: Folder? = nil

function Remotes.InitServer(): ()
	assert(RunService:IsServer(), "Remotes.InitServer() can only be called on the server.")

	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	local folder: Folder
	if existing and existing:IsA("Folder") then
		folder = existing
	else
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	for _, name in ipairs(REMOTE_NAMES) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end

	remotesFolder = folder
end

function Remotes.GetEvent(name: RemoteName): RemoteEvent
	local folder = remotesFolder
	if not folder then
		local found = ReplicatedStorage:WaitForChild(FOLDER_NAME)
		assert(found:IsA("Folder"), "Expected Remotes to be a Folder.")
		folder = found
		remotesFolder = found
	end

	local remote = (folder :: Folder):WaitForChild(name)
	assert(remote:IsA("RemoteEvent"), string.format("Remote '%s' is not a RemoteEvent.", name))
	return remote
end

return Remotes
