class_name PersistentData

# Persistent progression data that survives between runs
var total_gold_earned: int = 0
var total_kills: int = 0
var highest_floor_reached: int = 1
var games_played: int = 0
var permanent_upgrades: Dictionary = {
	"max_hp_bonus": 0,
	"atk_bonus": 0,
	"def_bonus": 0,
	"starting_gold": 0,
	"extra_potions": 0,
	"revival_amulet": false
}

# Shop unlockables
var shop_unlocks: Dictionary = {
	"health_potion": true,  # Always available
	"strength_potion": true,  # Always available  
	"shield_scroll": true,   # Always available
	"gold_bag": true,        # Always available
	"revival_amulet": false, # Unlocked at floor 10
	"teleport_scroll": false, # Unlocked at floor 15
	"blessing_scroll": false  # Unlocked at floor 20
}

func save() -> void:
	if OS.has_feature("JavaScript"):
		# HTML5 export - use localStorage
		var save_data: Dictionary = {
			"total_gold_earned": total_gold_earned,
			"total_kills": total_kills,
			"highest_floor_reached": highest_floor_reached,
			"games_played": games_played,
			"permanent_upgrades": permanent_upgrades.duplicate(),
			"shop_unlocks": shop_unlocks.duplicate()
		}
		JavaScript.eval("localStorage.setItem('depths_of_ruin_save', JSON.stringify(" + JSON.stringify(save_data) + "))")
	else:
		# Desktop/mobile - use config file
		var config: ConfigFile = ConfigFile.new()
		config.set_value("progress", "total_gold_earned", total_gold_earned)
		config.set_value("progress", "total_kills", total_kills)
		config.set_value("progress", "highest_floor_reached", highest_floor_reached)
		config.set_value("progress", "games_played", games_played)
		
		for key in permanent_upgrades:
			config.set_value("upgrades", key, permanent_upgrades[key])
			
		for key in shop_unlocks:
			config.set_value("shop_unlocks", key, shop_unlocks[key])
			
		config.save("user://depths_of_ruin.cfg")

func load() -> void:
	if OS.has_feature("JavaScript"):
		# HTML5 export - use localStorage
		var js_code: String = """
		try {
			var save_str = localStorage.getItem('depths_of_ruin_save');
			if (save_str) {
				return save_str;
			}
		} catch(e) {}
		return null;
		"""
		var result: String = JavaScript.eval(js_code)
		if result != "" and result != "null":
			var save_data: Dictionary = JSON.parse_string(result)
			if save_data:
				total_gold_earned = save_data.get("total_gold_earned", 0)
				total_kills = save_data.get("total_kills", 0)
				highest_floor_reached = save_data.get("highest_floor_reached", 1)
				games_played = save_data.get("games_played", 0)
				
				if save_data.has("permanent_upgrades"):
					permanent_upgrades = save_data["permanent_upgrades"]
				if save_data.has("shop_unlocks"):
					shop_unlocks = save_data["shop_unlocks"]
	else:
		# Desktop/mobile - use config file
		var config: ConfigFile = ConfigFile.new()
		if config.load("user://depths_of_ruin.cfg") == OK:
			total_gold_earned = config.get_value("progress", "total_gold_earned", 0)
			total_kills = config.get_value("progress", "total_kills", 0)
			highest_floor_reached = config.get_value("progress", "highest_floor_reached", 1)
			games_played = config.get_value("progress", "games_played", 0)
			
			for key in permanent_upgrades:
				permanent_upgrades[key] = config.get_value("upgrades", key, 0)
				
			for key in shop_unlocks:
				shop_unlocks[key] = config.get_value("shop_unlocks", key, false)

# Check if we should unlock new shop items based on progress
func check_shop_unlocks(floor_reached: int) -> void:
	if floor_reached >= 10:
		shop_unlocks["revival_amulet"] = true
	if floor_reached >= 15:
		shop_unlocks["teleport_scroll"] = true
	if floor_reached >= 20:
		shop_unlocks["blessing_scroll"] = true

# Update highest floor reached
func update_highest_floor(floor: int) -> void:
	if floor > highest_floor_reached:
		highest_floor_reached = floor
		check_shop_unlocks(highest_floor_reached)