class_name Trap

enum Type { 
	SPIKES,      # Deal damage when stepped on
	POISON_DART, # Deal damage and poison (DOT)
	FIRE_VENT,   # Periodic fire damage
	TELEPORT,    # Random teleport when stepped on
	# New themed traps
	ICE_PATCH,   # Slow effect
	LAVA_CRACK,  # Burn damage over time
	SHADOW_PIT,  # Teleport to random position + damage
	SPIRIT_WISP  # Drains XP (small amount)
}

var pos: Vector2i
var type: Type
var visible: bool = false
var triggered: bool = false
var cooldown: int = 0  # For fire vents
var name_str: String

func setup(t: Type, position: Vector2i) -> void:
	pos = position
	type = t
	visible = false
	triggered = false
	cooldown = 0
	match t:
		Type.SPIKES:
			name_str = "Spike Trap"
		Type.POISON_DART:
			name_str = "Poison Dart Trap"
		Type.FIRE_VENT:
			name_str = "Fire Vent"
		Type.TELEPORT:
			name_str = "Teleport Trap"
		Type.ICE_PATCH:
			name_str = "Ice Patch"
		Type.LAVA_CRACK:
			name_str = "Lava Crack"
		Type.SHADOW_PIT:
			name_str = "Shadow Pit"
		Type.SPIRIT_WISP:
			name_str = "Spirit Wisp"
		Type.ICE_PATCH:
			name_str = "Ice Patch"
		Type.LAVA_CRACK:
			name_str = "Lava Crack"
		Type.SHADOW_PIT:
			name_str = "Shadow Pit"
		Type.SPIRIT_WISP:
			name_str = "Spirit Wisp"

func get_color() -> Color:
	match type:
		Type.SPIKES:
			return Color(0.6, 0.4, 0.3)  # Brown/rust
		Type.POISON_DART:
			return Color(0.3, 0.7, 0.2)  # Green
		Type.FIRE_VENT:
			return Color(0.9, 0.3, 0.1)  # Orange-red
		Type.TELEPORT:
			return Color(0.5, 0.3, 0.8)  # Purple
		Type.ICE_PATCH:
			return Color(0.5, 0.8, 0.9)  # Light blue
		Type.LAVA_CRACK:
			return Color(0.9, 0.2, 0.1)  # Bright red
		Type.SHADOW_PIT:
			return Color(0.2, 0.1, 0.3)  # Dark purple
		Type.SPIRIT_WISP:
			return Color(0.7, 0.7, 0.9)  # Pale blue-white
	return Color.WHITE

# Returns true if trap should be consumed/destroyed after triggering
func is_one_shot() -> bool:
	match type:
		Type.SPIKES, Type.POISON_DART:
			return true
		Type.FIRE_VENT, Type.TELEPORT, Type.ICE_PATCH, Type.LAVA_CRACK, Type.SHADOW_PIT:
			return false
		Type.SPIRIT_WISP:
			return true  # One-shot trap
	return false
