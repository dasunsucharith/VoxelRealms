--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)

local VOXEL_SIZE = Constants.VOXEL_SIZE_STUDS

local VoxelGrid = {}

function VoxelGrid.worldToGrid(worldPosition: Vector3): Vector3
	return Vector3.new(
		math.floor((worldPosition.X / VOXEL_SIZE) + 0.5),
		math.floor((worldPosition.Y / VOXEL_SIZE) + 0.5),
		math.floor((worldPosition.Z / VOXEL_SIZE) + 0.5)
	)
end

function VoxelGrid.gridToWorld(gridCoord: Vector3): Vector3
	return Vector3.new(
		math.round(gridCoord.X) * VOXEL_SIZE,
		math.round(gridCoord.Y) * VOXEL_SIZE,
		math.round(gridCoord.Z) * VOXEL_SIZE
	)
end

function VoxelGrid.gridToKey(gridCoord: Vector3): string
	return string.format("%d,%d,%d", math.round(gridCoord.X), math.round(gridCoord.Y), math.round(gridCoord.Z))
end

function VoxelGrid.isWithinReach(origin: Vector3, gridCoord: Vector3, maxReachStuds: number): boolean
	local targetWorld = VoxelGrid.gridToWorld(gridCoord)
	return (targetWorld - origin).Magnitude <= maxReachStuds
end

return VoxelGrid
