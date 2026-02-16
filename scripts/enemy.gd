class_name Enemy

enum Type { SLIME, BAT, SKELETON, ORC }

var pos: Vector2i
var hp: int
var max_hp: int
var atk: int
var def: int
var type: Type
var alive: bool = true
var name_str: String

func setup(t: Type, position: Vector2i) -> void:
	pos = position
	type = t
	alive = true
	match t:
		Type.SLIME:
			hp = 3; max_hp = 3; atk = 1; def = 0
			name_str = "Slime"
		Type.BAT:
			hp = 2; max_hp = 2; atk = 2; def = 0
			name_str = "Bat"
		Type.SKELETON:
			hp = 5; max_hp = 5; atk = 2; def = 1
			name_str = "Skeleton"
		Type.ORC:
			hp = 8; max_hp = 8; atk = 3; def = 2
			name_str = "Orc"

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
	return Color.WHITE

func take_damage(amount: int) -> int:
	var dmg: int = maxi(1, amount - def)
	hp -= dmg
	if hp <= 0:
		hp = 0
		alive = false
	return dmg
