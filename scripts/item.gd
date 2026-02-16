class_name Item

enum Type { HEALTH_POTION, STRENGTH_POTION, SHIELD_SCROLL, GOLD }

var pos: Vector2i
var type: Type
var collected: bool = false
var name_str: String

func setup(t: Type, position: Vector2i) -> void:
	pos = position
	type = t
	collected = false
	match t:
		Type.HEALTH_POTION:
			name_str = "Health Potion"
		Type.STRENGTH_POTION:
			name_str = "Strength Potion"
		Type.SHIELD_SCROLL:
			name_str = "Shield Scroll"
		Type.GOLD:
			name_str = "Gold"

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
	return Color.WHITE
