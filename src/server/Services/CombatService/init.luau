--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Config.Constants)
local Remotes = require(Shared.Network.Remotes)

local Server = ServerScriptService:WaitForChild("Server")
local CreatureService = require(Server.Services.CreatureService)
local EquipmentService = require(Server.Services.EquipmentService)
local RoleService = require(Server.Services.RoleService)
local SurvivalService = require(Server.Services.SurvivalService)

local CombatService = {}
local lastAttackByPlayer: { [Player]: number } = {}

function CombatService.Init(): ()
	-- Reserved for dependency setup.
end

function CombatService.Start(): ()
	local requestAttackRemote = Remotes.GetEvent("RequestAttack")
	local feedbackRemote = Remotes.GetEvent("CombatFeedback")

	Players.PlayerRemoving:Connect(function(player: Player)
		lastAttackByPlayer[player] = nil
	end)

	requestAttackRemote.OnServerEvent:Connect(function(player: Player, rawAimDir: unknown)
		local now = os.clock()
		local lastTime = lastAttackByPlayer[player] or 0
		if now - lastTime < Constants.MELEE_COOLDOWN_SEC then
			return
		end

		local survival = SurvivalService.GetState(player)
		if not survival or survival.stamina < Constants.MELEE_STAMINA_COST then
			return
		end

		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if not root or not root:IsA("BasePart") then
			return
		end

		lastAttackByPlayer[player] = now
		SurvivalService.ModifyStats(player, 0, -Constants.MELEE_STAMINA_COST, 0)

		local forward = root.CFrame.LookVector
		if typeof(rawAimDir) == "Vector3" and rawAimDir.Magnitude > 0.01 then
			forward = rawAimDir.Unit
		end

		local role = RoleService.GetPlayerRole(player)
		local roleMultiplier = if role.id == "hunter" or role.id == "blacksmith" then 1.25 else 1.0
		local toolMultiplier = EquipmentService.GetToolBonus(player, "combat")
		local damageMultiplier = roleMultiplier * toolMultiplier
		local damage = math.round(Constants.MELEE_DAMAGE * damageMultiplier)

		local targets = CreatureService.FindCreaturesInArc(root.Position, forward, Constants.MELEE_REACH_STUDS)
		for _, target in ipairs(targets) do
			local hitOk, hitPos = CreatureService.DamageCreature(target.id, damage, player)
			if hitOk and hitPos then
				feedbackRemote:FireClient(player, hitPos, damage, damageMultiplier > 1.0)
			end
		end
	end)
end

return CombatService
