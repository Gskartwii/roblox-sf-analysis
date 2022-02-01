local scenario = require(game.ReplicatedStorage.Declare)
local loaded_scenario: scenario.Sword? = nil
local sword = script.Parent :: Tool

local INITIAL = "INITIAL"
local SLASH = "SLASH"
local LUNGE = "LUNGE"
local REST = "REST"
local damage_state = INITIAL
local damage: { [string]: number? } = {}

local function sword_hit(target: BasePart)
	if target.Parent == nil then
    	return
	end
	local humanoid = target.Parent:FindFirstChildOfClass("Humanoid")
	local my_character = sword.Parent
	local my_player = game.Players:GetPlayerFromCharacter(myCharacter)
	local my_humanoid = myCharacter:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid == my_humanoid or my_humanoid == nil then
    	return
	end
	if not loaded_scenario.allow_ties and my_humanoid.Health <= 0 then
		return
	end

	local right_arm = myCharacter:FindFirstChild("Right Arm")
	if right_arm == nil then
    	return
	end
	local joint = right_arm:FindFirstChild("Right Grip")
	if joint == nil or not (joint.Part0 == sword or joint.Part1 == sword) then
    	return
	end
	local dmg = damage[damage_state]
	if dmg ~= nil then
    	humanoid:TakeDamage(dmg)
	end
end

local function sword_activated()
	if not sword.Enabled then
    	return
	end
	sword.Enabled = false
end

local function load_scenario(player: Player, scenario: scenario.Sword)
	loaded_scenario = scenario
	damage_state = INITIAL
	damage = {
    	[INITIAL] = scenario.initial_damage,
    	[REST] = scenario.rest_damage or scenario.initial_damage,
	}
	local slash = scenario.slash
	if slash ~= nil then
    	damage[SLASH] = slash.damage
    	local lunge = slash.lunge
    	if lunge ~= nil then
        	damage[LUNGE] = lunge.damage
    	end
	end
end

local function unload_scenario(player: Player)
end
