class_name Enemy

enum Type { SLIME, BAT, SKELETON, ORC, WRAITH, FIRE_IMP, GOLEM, BOSS_SLIME, BOSS_LICH, BOSS_DRAGON }

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
var phase_through_walls: bool = false  # Wraith
var ranged_attack: bool = false  # Fire Imp

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
	match t:
		Type.SLIME:
			hp = 3; max_hp = 3; atk = 1; def = 0
			name_str = "Slime"; xp_value = 5
		Type.BAT:
			hp = 2; max_hp = 2; atk = 2; def = 0
			name_str = "Bat"; xp_value = 8
		Type.SKELETON:
			hp = 5; max_hp = 5; atk = 2; def = 1
			name_str = "Skeleton"; xp_value = 15
		Type.ORC:
			hp = 8; max_hp = 8; atk = 3; def = 2
			name_str = "Orc"; xp_value = 25
		Type.WRAITH:
			hp = 4; max_hp = 4; atk = 3; def = 0
			name_str = "Wraith"; xp_value = 20
			phase_through_walls = true
		Type.FIRE_IMP:
			hp = 3; max_hp = 3; atk = 4; def = 0
			name_str = "Fire Imp"; xp_value = 22
			ranged_attack = true
		Type.GOLEM:
			hp = 15; max_hp = 15; atk = 2; def = 4
			name_str = "Golem"; xp_value = 30
			move_cooldown = 0  # Moves every other turn
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
		Type.BOSS_SLIME:
			return Color(0.3, 0.85, 0.1)  # Large green
		Type.BOSS_LICH:
			return Color(0.6, 0.15, 0.8)  # Purple
		Type.BOSS_DRAGON:
			return Color(0.7, 0.1, 0.15)  # Dark red
	return Color.WHITE

func take_damage(amount: int) -> int:
	var dmg: int = maxi(1, amount - def)
	hp -= dmg
	if hp <= 0:
		hp = 0
		alive = false
	return dmg
