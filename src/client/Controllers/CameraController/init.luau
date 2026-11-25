--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)

local CameraController = {}
local localPlayer = Players.LocalPlayer
local isFirstPerson = false

function CameraController.SetFirstPerson(enabled: boolean): ()
	isFirstPerson = enabled
	if enabled then
		localPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
		localPlayer.CameraMinZoomDistance = Constants.FIRST_PERSON_ZOOM
		localPlayer.CameraMaxZoomDistance = Constants.FIRST_PERSON_ZOOM
	else
		localPlayer.CameraMode = Enum.CameraMode.Classic
		localPlayer.CameraMinZoomDistance = Constants.THIRD_PERSON_MIN_ZOOM
		localPlayer.CameraMaxZoomDistance = Constants.THIRD_PERSON_MAX_ZOOM
	end
end

function CameraController.TogglePerspective(): ()
	CameraController.SetFirstPerson(not isFirstPerson)
end

function CameraController.Init(): ()
	CameraController.SetFirstPerson(false)
end

function CameraController.Start(): ()
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.V then
			CameraController.TogglePerspective()
		end
	end)
end

return CameraController
