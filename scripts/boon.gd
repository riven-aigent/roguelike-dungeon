class_name Boon

enum Type {
	# Minor boons (shrine drops)
	VIGOR,        # +3 Max HP
	STRENGTH,     # +1 ATK
	FORTITUDE,    # +1 DEF
	SWIFT,        # +10% dodge chance
	
	# Major boons (rare drops)
	REGENERATION, # Heal 1 HP every 20 turns
	VAMPIRIC,     # Heal 1 HP per kill (stacks with affliction)
	LUCK,         # +10% gold find, +5% crit
	INSIGHT,      # +2 vision radius
	
	# Special boons (boss drops / rare)
	IRON_WILL,    # Immune to affliction effects (not application)
	BERSERKER,    # +3 ATK, +3 DEF when below 50% HP
	PHOENIX,      # Revive once with 25% HP on death
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
		Type.VIGOR:
			name_str = "Vigor"
			description = "+3 Max HP"
			boon_color = Color(0.3, 0.8, 0.3)
		Type.STRENGTH:
			name_str = "Strength"
			description = "+1 ATK"
			boon_color = Color(0.9, 0.5, 0.2)
		Type.FORTITUDE:
			name_str = "Fortitude"
			description = "+1 DEF"
			boon_color = Color(0.5, 0.6, 0.8)
		Type.SWIFT:
			name_str = "Swift"
			description = "+10% dodge"
			boon_color = Color(0.6, 0.9, 0.9)
		Type.REGENERATION:
			name_str = "Regeneration"
			description = "Heal 1 HP every 20 turns"
			boon_color = Color(0.2, 0.9, 0.4)
		Type.VAMPIRIC:
			name_str = "Vampiric"
			description = "Heal 1 HP per kill"
			boon_color = Color(0.7, 0.2, 0.3)
		Type.LUCK:
			name_str = "Luck"
			description = "+10% gold, +5% crit"
			boon_color = Color(0.9, 0.85, 0.2)
		Type.INSIGHT:
			name_str = "Insight"
			description = "+2 vision radius"
			boon_color = Color(0.4, 0.7, 1.0)
		Type.IRON_WILL:
			name_str = "Iron Will"
			description = "Immune to affliction effects"
			boon_color = Color(0.7, 0.7, 0.8)
		Type.BERSERKER:
			name_str = "Berserker"
			description = "+3 ATK/DEF below 50% HP"
			boon_color = Color(0.9, 0.3, 0.2)
		Type.PHOENIX:
			name_str = "Phoenix"
			description = "Revive once on death"
			boon_color = Color(1.0, 0.5, 0.1)

func get_stat_modifiers() -> Dictionary:
	var mods: Dictionary = {
		"max_hp_mod": 0,
		"atk_mod": 0,
		"def_mod": 0,
		"vision_mod": 0,
		"dodge_chance": 0.0,
		"crit_bonus": 0.0,
		"gold_bonus": 0.0,
		"heal_on_kill": 0,
		"affliction_immune": false,
		"revive": false,
	}
	
	match type:
		Type.VIGOR:
			mods["max_hp_mod"] = 3
		Type.STRENGTH:
			mods["atk_mod"] = 1
		Type.FORTITUDE:
			mods["def_mod"] = 1
		Type.SWIFT:
			mods["dodge_chance"] = 0.1
		Type.VAMPIRIC:
			mods["heal_on_kill"] = 1
		Type.LUCK:
			mods["gold_bonus"] = 0.1
			mods["crit_bonus"] = 0.05
		Type.INSIGHT:
			mods["vision_mod"] = 2
		Type.IRON_WILL:
			mods["affliction_immune"] = true
		Type.PHOENIX:
			mods["revive"] = true
	
	return mods

func should_trigger_regen() -> int:
	if type == Type.REGENERATION:
		if turns_active > 0 and turns_active % 20 == 0:
			return 1
	return 0

func get_berserker_bonus(current_hp: int, max_hp: int) -> Dictionary:
	if type == Type.BERSERKER:
		if float(current_hp) / float(max_hp) < 0.5:
			return {"atk": 3, "def": 3}
	return {"atk": 0, "def": 0}

func increment_turn() -> void:
	turns_active += 1
