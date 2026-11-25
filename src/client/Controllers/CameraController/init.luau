--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)

local CameraController = {}
local localPlayer = Players.LocalPlayer
local isFirstPerson = false
local toggleToken = 0

function CameraController.SetFirstPerson(enabled: boolean): ()
	isFirstPerson = enabled
	toggleToken += 1
	local currentToken = toggleToken

	-- Keep CameraMode in Classic so ZoomController reliably switches between 1st and 3rd person.
	localPlayer.CameraMode = Enum.CameraMode.Classic

	if enabled then
		localPlayer.CameraMinZoomDistance = Constants.FIRST_PERSON_ZOOM
		localPlayer.CameraMaxZoomDistance = Constants.FIRST_PERSON_ZOOM
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		-- Pin Min/Max to the default 3rd-person distance for two render frames so Roblox's
		-- ZoomController immediately snaps out of first-person before restoring scroll zoom.
		localPlayer.CameraMinZoomDistance = Constants.THIRD_PERSON_DEFAULT_ZOOM
		localPlayer.CameraMaxZoomDistance = Constants.THIRD_PERSON_DEFAULT_ZOOM

		task.spawn(function()
			RunService.RenderStepped:Wait()
			RunService.RenderStepped:Wait()
			if toggleToken == currentToken and not isFirstPerson then
				localPlayer.CameraMinZoomDistance = Constants.THIRD_PERSON_MIN_ZOOM
				localPlayer.CameraMaxZoomDistance = Constants.THIRD_PERSON_MAX_ZOOM
			end
		end)
	end
end

function CameraController.TogglePerspective(): ()
	CameraController.SetFirstPerson(not isFirstPerson)
end

function CameraController.IsFirstPerson(): boolean
	return isFirstPerson
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
