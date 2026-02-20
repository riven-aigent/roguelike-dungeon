class_name Affliction

enum Type {
	# Minor afflictions (appear floor 5+)
	FRAIL,  # -2 Max HP
	WEAKNESS,  # -1 ATK
	CLUMSY,  # -1 DEF
	HEAVY,  # Slow effect every 8 turns
	# Major afflictions (appear floor 10+)
	DECAY,  # Lose 1 HP every 15 turns
	HAUNTED,  # Ghosts spawn more frequently
	SHADOWED,  # Reduced vision radius (-2)
	TAINTED_GOLD,  # Gold pickups have 30% chance to damage you for 2
	# Special afflictions (boss drops / rare)
	VAMPIRIC,  # Heal 1 HP per kill, but lose 1 HP per 20 turns
	BERSERKER,  # +3 ATK, -5 Max HP
	GLASS_CANNON,  # +5 ATK, -10 Max HP, take double damage
	CURSED,  # Traps deal +2 damage
}

var type: Type
var name_str: String
var description: String
var affliction_color: Color
var is_permanent: bool = true
var turns_active: int = 0  # For tracking timed effects


func setup(t: Type) -> void:
	type = t
	turns_active = 0

	match t:
		Type.FRAIL:
			name_str = "Frail"
			description = "-2 Max HP"
			affliction_color = Color(0.7, 0.3, 0.3)
		Type.WEAKNESS:
			name_str = "Weakness"
			description = "-1 ATK"
			affliction_color = Color(0.6, 0.4, 0.3)
		Type.CLUMSY:
			name_str = "Clumsy"
			description = "-1 DEF"
			affliction_color = Color(0.5, 0.5, 0.3)
		Type.HEAVY:
			name_str = "Heavy"
			description = "Slowed every 8 turns"
			affliction_color = Color(0.4, 0.4, 0.5)
		Type.DECAY:
			name_str = "Decay"
			description = "Lose 1 HP every 15 turns"
			affliction_color = Color(0.5, 0.2, 0.5)
		Type.HAUNTED:
			name_str = "Haunted"
			description = "More ghosts spawn"
			affliction_color = Color(0.6, 0.6, 0.9, 0.7)
		Type.SHADOWED:
			name_str = "Shadowed"
			description = "-2 vision radius"
			affliction_color = Color(0.2, 0.2, 0.3)
		Type.TAINTED_GOLD:
			name_str = "Tainted Gold"
			description = "30% chance gold damages you"
			affliction_color = Color(0.8, 0.7, 0.2)
		Type.VAMPIRIC:
			name_str = "Vampiric"
			description = "Heal on kill, lose HP over time"
			affliction_color = Color(0.6, 0.1, 0.2)
		Type.BERSERKER:
			name_str = "Berserker"
			description = "+3 ATK, -5 Max HP"
			affliction_color = Color(0.9, 0.3, 0.2)
		Type.GLASS_CANNON:
			name_str = "Glass Cannon"
			description = "+5 ATK, -10 Max HP, 2x damage taken"
			affliction_color = Color(0.9, 0.9, 0.9)
		Type.CURSED:
			name_str = "Cursed"
			description = "Traps deal +2 damage"
			affliction_color = Color(0.4, 0.2, 0.6)


func get_stat_modifiers() -> Dictionary:
	# Returns {max_hp_mod, atk_mod, def_mod, vision_mod, damage_mult}
	var mods: Dictionary = {
		"max_hp_mod": 0,
		"atk_mod": 0,
		"def_mod": 0,
		"vision_mod": 0,
		"damage_mult": 1.0,
		"heal_on_kill": 0,
	}

	match type:
		Type.FRAIL:
			mods["max_hp_mod"] = -2
		Type.WEAKNESS:
			mods["atk_mod"] = -1
		Type.CLUMSY:
			mods["def_mod"] = -1
		Type.SHADOWED:
			mods["vision_mod"] = -2
		Type.VAMPIRIC:
			mods["heal_on_kill"] = 1
		Type.BERSERKER:
			mods["atk_mod"] = 3
			mods["max_hp_mod"] = -5
		Type.GLASS_CANNON:
			mods["atk_mod"] = 5
			mods["max_hp_mod"] = -10
			mods["damage_mult"] = 2.0

	return mods


func should_trigger_slow() -> bool:
	if type == Type.HEAVY:
		return turns_active > 0 and turns_active % 8 == 0
	return false


func should_trigger_decay() -> int:
	# Returns HP to lose (0 if not triggered)
	if type == Type.DECAY:
		if turns_active > 0 and turns_active % 15 == 0:
			return 1
	if type == Type.VAMPIRIC:
		if turns_active > 0 and turns_active % 20 == 0:
			return 1
	return 0


func should_trigger_tainted_gold() -> bool:
	if type == Type.TAINTED_GOLD:
		return randf() < 0.3
	return false


func get_ghost_spawn_bonus() -> float:
	if type == Type.HAUNTED:
		return 0.15  # 15% extra chance
	return 0.0


func increment_turn() -> void:
	turns_active += 1
