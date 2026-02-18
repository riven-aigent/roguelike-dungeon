class_name Enemy

const Item = preload("res://scripts/item.gd")
enum Type { SLIME, BAT, SKELETON, ORC, WRAITH, FIRE_IMP, GOLEM, GHOST, SPIDER, MIMIC, BOSS_SLIME, BOSS_LICH, BOSS_DRAGON, VAMPIRE, TROLL, CRYSTAL_GOLEM, SHADOW }

var pos: Vector2i
var hp: int
var max_hp: int
var atk: int
var def: int
var type: Type
var alive: bool = true
var name_str: String
var xp_value: int = 5

# Special enemy state
var move_cooldown: int = 0  # Golem: skip turns
var summon_timer: int = 0   # Lich: summon counter
var actions_per_turn: int = 1  # Dragon: 2 actions
var has_split: bool = false  # Giant Slime: split once at 50%
var is_boss: bool = false
var phase_through_walls: bool = false  # Wraith, Ghost
var ranged_attack: bool = false  # Fire Imp
var web_attack: bool = false  # Spider: slows player
var stealthed: bool = false  # Ghost: invisible until close
var mimic_revealed: bool = false  # Mimic: disguised as item

# Loot drops
var drop_chance: float = 0.0  # Chance to drop equipment
var guaranteed_drop: int = -1  # Item type to always drop (-1 = none)

func setup(t: Type, position: Vector2i) -> void:
	pos = position
	type = t
	alive = true
	has_split = false
	move_cooldown = 0
	summon_timer = 0
	actions_per_turn = 1
	is_boss = false
	phase_through_walls = false
	ranged_attack = false
	web_attack = false
	stealthed = false
	mimic_revealed = false
	drop_chance = 0.0
	guaranteed_drop = -1
	
	match t:
		Type.SLIME:
			hp = 3; max_hp = 3; atk = 1; def = 0
			name_str = "Slime"; xp_value = 5
			drop_chance = 0.05
		Type.BAT:
			hp = 2; max_hp = 2; atk = 2; def = 0
			name_str = "Bat"; xp_value = 8
			drop_chance = 0.05
		Type.SKELETON:
			hp = 5; max_hp = 5; atk = 2; def = 1
			name_str = "Skeleton"; xp_value = 15
			drop_chance = 0.15
		Type.ORC:
			hp = 8; max_hp = 8; atk = 3; def = 2
			name_str = "Orc"; xp_value = 25
			drop_chance = 0.2
		Type.WRAITH:
			hp = 4; max_hp = 4; atk = 3; def = 0
			name_str = "Wraith"; xp_value = 20
			phase_through_walls = true
			drop_chance = 0.15
		Type.FIRE_IMP:
			hp = 3; max_hp = 3; atk = 4; def = 0
			name_str = "Fire Imp"; xp_value = 22
			ranged_attack = true
			drop_chance = 0.1
		Type.GOLEM:
			hp = 15; max_hp = 15; atk = 2; def = 4
			name_str = "Golem"; xp_value = 30
			move_cooldown = 0  # Moves every other turn
			drop_chance = 0.3
		Type.GHOST:
			hp = 3; max_hp = 3; atk = 5; def = 0
			name_str = "Ghost"; xp_value = 28
			phase_through_walls = true
			stealthed = true  # Invisible until adjacent
			drop_chance = 0.2
		Type.SPIDER:
			hp = 4; max_hp = 4; atk = 2; def = 0
			name_str = "Spider"; xp_value = 18
			web_attack = true  # Slows player
			drop_chance = 0.1
		Type.MIMIC:
			hp = 12; max_hp = 12; atk = 4; def = 2
			name_str = "Mimic"; xp_value = 35
			mimic_revealed = false
			drop_chance = 0.5  # High drop chance
			guaranteed_drop = Item.Type.GOLD  # Always drops gold
		Type.BOSS_SLIME:
			hp = 25; max_hp = 25; atk = 4; def = 2
			name_str = "Giant Slime"; xp_value = 80
			is_boss = true
		Type.BOSS_LICH:
			hp = 30; max_hp = 30; atk = 5; def = 3
			name_str = "Lich"; xp_value = 120
			is_boss = true
			summon_timer = 0
		Type.BOSS_DRAGON:
			hp = 50; max_hp = 50; atk = 6; def = 4
			name_str = "Shadow Dragon"; xp_value = 200
			is_boss = true
			actions_per_turn = 2
		Type.VAMPIRE:
			hp = 10; max_hp = 10; atk = 4; def = 1
			name_str = "Vampire"; xp_value = 40
			drop_chance = 0.25
		Type.TROLL:
			hp = 20; max_hp = 20; atk = 3; def = 2
			name_str = "Troll"; xp_value = 45
			drop_chance = 0.2
		Type.CRYSTAL_GOLEM:
			hp = 18; max_hp = 18; atk = 2; def = 6
			name_str = "Crystal Golem"; xp_value = 50
			move_cooldown = 0
			drop_chance = 0.35
		Type.SHADOW:
			hp = 6; max_hp = 6; atk = 5; def = 0
			name_str = "Shadow"; xp_value = 35
			phase_through_walls = true
			drop_chance = 0.15

func get_color() -> Color:
	match type:
		Type.SLIME:
			return Color(0.6, 0.9, 0.2)
		Type.BAT:
			return Color(0.6, 0.2, 0.8)
		Type.SKELETON:
			return Color(0.9, 0.9, 0.9)
		Type.ORC:
			return Color(0.6, 0.1, 0.1)
		Type.WRAITH:
			return Color(0.3, 0.5, 0.95, 0.7)  # Translucent blue
		Type.FIRE_IMP:
			return Color(1.0, 0.4, 0.1)  # Orange-red
		Type.GOLEM:
			return Color(0.4, 0.4, 0.45)  # Dark gray
		Type.GHOST:
			return Color(0.8, 0.9, 1.0, 0.5)  # Translucent white
		Type.SPIDER:
			return Color(0.3, 0.2, 0.15)  # Dark brown
		Type.MIMIC:
			if mimic_revealed:
				return Color(0.7, 0.5, 0.2)  # Brown when revealed
			else:
				return Color(1.0, 0.85, 0.1)  # Looks like gold
		Type.BOSS_SLIME:
			return Color(0.3, 0.85, 0.1)  # Large green
		Type.BOSS_LICH:
			return Color(0.6, 0.15, 0.8)  # Purple
		Type.BOSS_DRAGON:
			return Color(0.7, 0.1, 0.15)  # Dark red
		Type.VAMPIRE:
			return Color(0.7, 0.1, 0.3)  # Dark red
		Type.TROLL:
			return Color(0.4, 0.5, 0.3)  # Green-brown
		Type.CRYSTAL_GOLEM:
			return Color(0.6, 0.8, 1.0, 0.8)  # Translucent blue
		Type.SHADOW:
			return Color(0.1, 0.1, 0.15, 0.6)  # Near-black translucent
	return Color.WHITE

func take_damage(amount: int) -> int:
	var dmg: int = maxi(1, amount - def)
	hp -= dmg
	if hp <= 0:
		hp = 0
		alive = false
	# Reveal mimic when damaged
	if type == Type.MIMIC and not mimic_revealed:
		mimic_revealed = true
	# Reveal ghost when damaged
	if type == Type.GHOST and stealthed:
		stealthed = false
	return dmg

func is_visible_to_player() -> bool:
	# Ghost is invisible until adjacent or damaged
	if type == Type.GHOST and stealthed:
		return false
	return true