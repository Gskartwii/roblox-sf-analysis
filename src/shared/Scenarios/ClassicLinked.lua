--!strict
--
local scenario = require(script.Parent.Declare)
local timing = scenario.timing

return {
	physics = {
		walk_speed = 16,
		gravity = 196.2,
	} :: scenario.Physics,
	health = {
		max_health = 100,
		initial_health = 100,
		regen_rate_hp = 1,
		regen_interval_sec = 1.0,
	} :: scenario.Health,
	slash = {
    	lunge_opportunity = timing(0, 0.2),
    	damage = 10,
    	damage_timing = timing(0, 0),
		next_damage = 10,
		oa_whip_timing = timing(0, 0.3),
	} :: scenario.Slash,
	lunge = {
		boost = {
			velocity = Vector3.new(0, 10, 0),
			max_force = Vector3.new(0, math.huge, 0),
			timing = timing(0, 0.5),
		} :: scenario.LungeBoost,
		sword_out_timing = timing(0.25, 0.75),
		damage_timing = timing(0, 1),
		damage = 30,
		next_damage = 10,
		oa_whip_timing = timing(0, 0.3),
	} :: scenario.Lunge,
	initial_damage = 5,
	allow_ties = true,
} :: scenario.Scenario
