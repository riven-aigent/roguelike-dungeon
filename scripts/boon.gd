class_name Boon

enum Type {
	# Minor boons (rare drops)
	FORTITUDE,  # +3 Max HP
	VIGOR,  # +1 HP regen every 25 turns
	SWIFT,  # +1 movement speed (dodge chance +10%)
	STRENGTH,  # +2 ATK
	# Major boons (elite/boss drops)
	REGENERATION,  # Regen 2 HP every 20 turns
	LUCK,  # +20% gold drops
	INSIGHT,  # +2 vision radius
	IRON_WILL,  # +3 DEF
	# Legendary boons (boss drops only)
	PHOENIX,  # Revive once with 25% HP
	SHADOW_WALK,  # 25% dodge chance
	MIRROR_SHIELD,  # Reflect 25% damage
	BERSERKER,  # +3 ATK, +3 DEF when below 50% HP
	VAMPIRIC,  # Heal 2 HP per kill
}

var type: Type
var name_str: String
var description: String
var boon_color: Color
var turns_active: int = 0


func setup(t: Type) -> void:
	type = t
	turns_active = 0
	
	match t:
		Type.FORTITUDE:
			name_str = "Fortitude"
			description = "+3 Max HP"
			boon_color = Color(0.3, 0.7, 0.3)
		Type.VIGOR:
			name_str = "Vigor"
			description = "Regen 1 HP every 25 turns"
			boon_color = Color(0.4, 0.8, 0.4)
		Type.SWIFT:
			name_str = "Swift"
			description = "+10% dodge chance"
			boon_color = Color(0.3, 0.6, 0.8)
		Type.STRENGTH:
			name_str = "Strength"
			description = "+2 ATK"
			boon_color = Color(0.8, 0.4, 0.3)
		Type.REGENERATION:
			name_str = "Regeneration"
			description = "Regen 2 HP every 20 turns"
			boon_color = Color(0.5, 0.8, 0.5)
		Type.LUCK:
			name_str = "Luck"
			description = "+20% gold drops"
			boon_color = Color(0.9, 0.8, 0.2)
		Type.INSIGHT:
			name_str = "Insight"
			description = "+2 vision radius"
			boon_color = Color(0.8, 0.7, 0.3)
		Type.IRON_WILL:
			name_str = "Iron Will"
			description = "+3 DEF"
			boon_color = Color(0.5, 0.5, 0.6)
		Type.PHOENIX:
			name_str = "Phoenix Heart"
			description = "Revive once with 25% HP"
			boon_color = Color(1.0, 0.5, 0.2)
		Type.SHADOW_WALK:
			name_str = "Shadow Walk"
			description = "25% dodge chance"
			boon_color = Color(0.4, 0.3, 0.6)
		Type.MIRROR_SHIELD:
			name_str = "Mirror Shield"
			description = "Reflect 25% damage"
			boon_color = Color(0.6, 0.7, 0.8)
		Type.BERSERKER:
			name_str = "Berserker"
			description = "+3 ATK/DEF when HP < 50%"
			boon_color = Color(0.9, 0.3, 0.2)
		Type.VAMPIRIC:
			name_str = "Vampiric"
			description = "Heal 2 HP per kill"
			boon_color = Color(0.7, 0.2, 0.3)


func get_stat_modifiers() -> Dictionary:
	var mods: Dictionary = {
		"max_hp_mod": 0,
		"atk_mod": 0,
		"def_mod": 0,
		"vision_mod": 0,
		"dodge_chance": 0.0,
		"gold_bonus": 0.0,
		"heal_on_kill": 0,
		"damage_reflect": 0.0,
	}
	
	match type:
		Type.FORTITUDE:
			mods["max_hp_mod"] = 3
		Type.SWIFT:
			mods["dodge_chance"] = 0.1
		Type.STRENGTH:
			mods["atk_mod"] = 2
		Type.LUCK:
			mods["gold_bonus"] = 0.2
		Type.INSIGHT:
			mods["vision_mod"] = 2
		Type.IRON_WILL:
			mods["def_mod"] = 3
		Type.SHADOW_WALK:
			mods["dodge_chance"] = 0.25
		Type.MIRROR_SHIELD:
			mods["damage_reflect"] = 0.25
		Type.VAMPIRIC:
			mods["heal_on_kill"] = 2
	
	return mods


func should_trigger_regen() -> int:
	if type == Type.VIGOR:
		if turns_active > 0 and turns_active % 25 == 0:
			return 1
	if type == Type.REGENERATION:
		if turns_active > 0 and turns_active % 20 == 0:
			return 2
	return 0


func increment_turn() -> void:
	turns_active += 1
