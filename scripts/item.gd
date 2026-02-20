class_name Item

enum Type { 
	HEALTH_POTION, 
	STRENGTH_POTION, 
	SHIELD_SCROLL,
	GOLD,
	REVIVAL_AMULET,
	TELEPORT_SCROLL,
	BLESSING_SCROLL,
	KEY,           # Opens secret walls
	BOMB,          # Destroys nearby walls
	POISON_CURE,   # Cures poison status
	# New consumables
	FIRE_BOMB,     # Damages all enemies in 3x3 area
	FROST_SCROLL,  # Freezes all visible enemies for 3 turns
	SHADOW_STEP,   # Teleport through walls to visible tile
	# Affliction items (dark tomes)
	DARK_TOME,     # Applies a random affliction but gives 50 XP
	TAINTED_GEM,   # Applies an affliction but reveals all enemies on floor
	# Equipment
	SWORD,         # +2 ATK
	AXE,           # +3 ATK, -1 DEF
	DAGGER,        # +1 ATK, +5% crit
	SHIELD,        # +2 DEF
	ARMOR,         # +3 DEF, -1 move speed (not implemented yet)
	RING_POWER,    # +1 ATK, +1 DEF
	AMULET_LIFE,   # +10 MAX HP
	BOOTS_SPEED,   # +1 move speed (future)
	RING_CRIT,     # +15% crit chance
	CLOAK_SHADOW,  # +20% dodge chance (future)
	POTION_MANA,   # Restores mana (future magic system)
	# New equipment
	GREATSWORD,    # +4 ATK, -1 DEF
	SPEAR,         # +2 ATK, +1 DEF, can attack 2 tiles
	RING_VAMPIRE,  # +5% lifesteal
	AMULET_FURY,   # +2 ATK, +10% crit
	# Boon items (shrines)
	ANCIENT_SHRINE,    # Grants a random boon
	PURIFYING_ELIXIR,  # Cures all afflictions
	SACRED_FLAME,      # +2 ATK for current floor
	# End of enum
}

enum EquipmentSlot { WEAPON, ARMOR, ACCESSORY }

var pos: Vector2i
var type: Type
var collected: bool = false
var name_str: String
var is_equipment: bool = false
var equipment_slot: int = -1
var atk_bonus: int = 0
var def_bonus: int = 0
var hp_bonus: int = 0
var crit_bonus: float = 0.0

func setup(t: Type, position: Vector2i) -> void:
	pos = position
	type = t
	collected = false
	is_equipment = false
	equipment_slot = -1
	atk_bonus = 0
	def_bonus = 0
	hp_bonus = 0
	crit_bonus = 0.0
	
	match t:
		Type.HEALTH_POTION:
			name_str = "Health Potion"
		Type.STRENGTH_POTION:
			name_str = "Strength Potion"
		Type.SHIELD_SCROLL:
			name_str = "Shield Scroll"
		Type.GOLD:
			name_str = "Gold"
		Type.REVIVAL_AMULET:
			name_str = "Revival Amulet"
		Type.TELEPORT_SCROLL:
			name_str = "Teleport Scroll"
		Type.BLESSING_SCROLL:
			name_str = "Blessing Scroll"
		Type.KEY:
			name_str = "Dungeon Key"
		Type.BOMB:
			name_str = "Bomb"
		Type.POISON_CURE:
			name_str = "Antidote"
		Type.FIRE_BOMB:
			name_str = "Fire Bomb"
		Type.FROST_SCROLL:
			name_str = "Frost Scroll"
		Type.SHADOW_STEP:
			name_str = "Shadow Step"
		# Affliction items
		Type.DARK_TOME:
			name_str = "Dark Tome"
		Type.TAINTED_GEM:
			name_str = "Tainted Gem"
		# Equipment
		Type.SWORD:
			name_str = "Iron Sword"
			is_equipment = true
			equipment_slot = EquipmentSlot.WEAPON
			atk_bonus = 2
		Type.AXE:
			name_str = "Battle Axe"
			is_equipment = true
			equipment_slot = EquipmentSlot.WEAPON
			atk_bonus = 3
			def_bonus = -1
		Type.DAGGER:
			name_str = "Shadow Dagger"
			is_equipment = true
			equipment_slot = EquipmentSlot.WEAPON
			atk_bonus = 1
			crit_bonus = 0.1
		Type.SHIELD:
			name_str = "Iron Shield"
			is_equipment = true
			equipment_slot = EquipmentSlot.ARMOR
			def_bonus = 2
		Type.ARMOR:
			name_str = "Chain Mail"
			is_equipment = true
			equipment_slot = EquipmentSlot.ARMOR
			def_bonus = 3
		Type.RING_POWER:
			name_str = "Ring of Power"
			is_equipment = true
			equipment_slot = EquipmentSlot.ACCESSORY
			atk_bonus = 1
			def_bonus = 1
		Type.AMULET_LIFE:
			name_str = "Amulet of Life"
			is_equipment = true
			equipment_slot = EquipmentSlot.ACCESSORY
			hp_bonus = 10
		Type.BOOTS_SPEED:
			name_str = "Boots of Speed"
			is_equipment = true
			equipment_slot = EquipmentSlot.ACCESSORY
		Type.GREATSWORD:
			name_str = "Greatsword"
			is_equipment = true
			equipment_slot = EquipmentSlot.WEAPON
			atk_bonus = 4
			def_bonus = -1
		Type.SPEAR:
			name_str = "Spear"
			is_equipment = true
			equipment_slot = EquipmentSlot.WEAPON
			atk_bonus = 2
			def_bonus = 1
	Type.RING_VAMPIRE:
			name_str = "Ring of Vampirism"
			is_equipment = true
			equipment_slot = EquipmentSlot.ACCESSORY
		Type.AMULET_FURY:
			name_str = "Amulet of Fury"
			is_equipment = true
			equipment_slot = EquipmentSlot.ACCESSORY
			atk_bonus = 2
			crit_bonus = 0.1
		Type.RING_CRIT:
			name_str = "Ring of Critical"
			is_equipment = true
			equipment_slot = EquipmentSlot.ACCESSORY
			crit_bonus = 0.15
		Type.CLOAK_SHADOW:
			name_str = "Cloak of Shadows"
			is_equipment = true
			equipment_slot = EquipmentSlot.ACCESSORY
		# Boon items
		Type.ANCIENT_SHRINE:
			name_str = "Ancient Shrine"
		Type.PURIFYING_ELIXIR:
			name_str = "Purifying Elixir"
		Type.SACRED_FLAME:
			name_str = "Sacred Flame"

func get_color() -> Color:
	match type:
		Type.HEALTH_POTION:
			return Color(0.9, 0.15, 0.15)
		Type.STRENGTH_POTION:
			return Color(1.0, 0.6, 0.1)
		Type.SHIELD_SCROLL:
			return Color(0.3, 0.5, 1.0)
		Type.GOLD:
			return Color(1.0, 0.85, 0.1)
		Type.REVIVAL_AMULET:
			return Color(0.9, 0.2, 0.8)  # Pink/purple
		Type.TELEPORT_SCROLL:
			return Color(0.7, 0.3, 0.9)  # Purple
		Type.BLESSING_SCROLL:
			return Color(0.9, 0.9, 0.3)  # Yellow/gold
		Type.KEY:
			return Color(0.8, 0.7, 0.2)  # Gold/bronze
		Type.BOMB:
			return Color(0.3, 0.3, 0.35)  # Dark gray
		Type.POISON_CURE:
			return Color(0.4, 0.9, 0.5)  # Light green
		Type.FIRE_BOMB:
			return Color(0.9, 0.3, 0.1)  # Bright red-orange
		Type.FROST_SCROLL:
			return Color(0.5, 0.8, 1.0)  # Ice blue
		Type.SHADOW_STEP:
			return Color(0.3, 0.2, 0.5)  # Dark purple
		# Affliction items
		Type.DARK_TOME:
			return Color(0.4, 0.1, 0.5)  # Dark purple
		Type.TAINTED_GEM:
			return Color(0.5, 0.1, 0.3)  # Dark red-purple
		# Equipment colors
		Type.SWORD:
			return Color(0.7, 0.7, 0.8)  # Silver
		Type.AXE:
			return Color(0.6, 0.4, 0.3)  # Bronze/brown
		Type.DAGGER:
			return Color(0.3, 0.3, 0.4)  # Dark steel
		Type.SHIELD:
			return Color(0.5, 0.5, 0.6)  # Gray
		Type.ARMOR:
			return Color(0.4, 0.4, 0.5)  # Dark gray
		Type.RING_POWER:
			return Color(0.9, 0.5, 0.1)  # Orange-gold
		Type.AMULET_LIFE:
			return Color(0.2, 0.8, 0.3)  # Green
		Type.BOOTS_SPEED:
			return Color(0.3, 0.6, 0.9)  # Blue
		Type.GREATSWORD:
			return Color(0.8, 0.75, 0.85)  # Bright silver
		Type.SPEAR:
			return Color(0.6, 0.55, 0.5)  # Brown wooden shaft
		Type.RING_VAMPIRE:
			return Color(0.6, 0.1, 0.2)  # Dark red
	Type.AMULET_FURY:
			return Color(0.9, 0.3, 0.2)  # Red-orange
		Type.RING_CRIT:
			return Color(0.9, 0.8, 0.2)  # Yellow-gold
		Type.CLOAK_SHADOW:
			return Color(0.2, 0.15, 0.3)  # Dark purple
	return Color.WHITE

func get_description() -> String:
	if is_equipment:
		var desc: String = ""
		if atk_bonus != 0:
			desc += ("+" if atk_bonus > 0 else "") + str(atk_bonus) + " ATK "
		if def_bonus != 0:
			desc += ("+" if def_bonus > 0 else "") + str(def_bonus) + " DEF "
		if hp_bonus != 0:
			desc += ("+" if hp_bonus > 0 else "") + str(hp_bonus) + " HP "
		if crit_bonus > 0:
			desc += "+" + str(int(crit_bonus * 100)) + "% Crit "
		return desc.strip_edges()
	return ""