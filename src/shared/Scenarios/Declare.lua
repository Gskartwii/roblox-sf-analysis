--!strict

export type Timing = {
	delay: number?,
	length: number,
}
export type Sound = {
    source: string,
    volume: number,
    delay: number?,
}

export type LungeBoost = {
	velocity: Vector3,
	max_force: Vector3?,
	timing: Timing,
}
export type Lunge = {
    opportunity_in_slash: Timing,
	boost: LungeBoost?,
	sword_out_timing: Timing?,
	damage: number,
	damage_opportunity: Timing,
	oa_whip_timing: Timing,
	sound: Sound?,
	cursor: string?,
	next_cursor: string?,
}
export type Slash = {
    lunge: Lunge?,
    damage: number,
    damage_opportunity: Timing,
	oa_whip_timing: Timing,
	sound: Sound?,
	cursor: string?,
	next_cursor: string?,
}

export type Health = {
    max_health: number?,
    initial_health: number?,
    regen_rate_hp: number?,
    regen_interval_sec: number?,
}

export type Physics = {
    walk_speed: number?,
    gravity: number?,
}

export type Sword = {
    slash: Slash?,
    initial_damage: number,
    rest_damage: number?,
    allow_ties: boolean,
    equip_sound: Sound?,
    unequip_sound: Sound?,
}

export type Scenario = {
    physics: Physics?,
    health: Health?,
    swords: { [number]: Sword },
}

return {
    timing = function(length: number, delay: number?): Timing
		return {delay = delay, length = length}
    end
}
