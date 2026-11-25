--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Network.Remotes)
local GameTypes = require(Shared.Types.GameTypes)

type BlockId = GameTypes.BlockId

local BuildController = {}
local activeBlockId: BlockId = "plank"

function BuildController.SetActiveBlock(blockId: BlockId): ()
	activeBlockId = blockId
end

function BuildController.RequestPlace(gridCoord: Vector3): ()
	Remotes.GetEvent("PlaceVoxel"):FireServer(gridCoord, activeBlockId)
end

function BuildController.RequestRemove(gridCoord: Vector3): ()
	Remotes.GetEvent("RemoveVoxel"):FireServer(gridCoord)
end

function BuildController.Init(): ()
	-- Sprint 1: Initialize translucent voxel placement ghost preview here.
end

function BuildController.Start(): ()
	-- Sprint 1: Bind mouse raycast + Left/Right click to RequestPlace / RequestRemove.
end

return BuildController
