extends Node2D
# Load all required scripts
const PersistentData = preload("res://scripts/persistent_data.gd")
const ShopSystem = preload("res://scripts/shop_system.gd")
const Trap = preload("res://scripts/trap.gd")
const TileMapData = preload("res://scripts/tile_map_data.gd")
const DungeonGenerator = preload("res://scripts/dungeon_generator.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Item = preload("res://scripts/item.gd")
const ShopUI = preload("res://scripts/shop_ui.gd")

const TILE_SIZE := 32
# Persistent progression
var persistent_data: PersistentData
var shop_system: ShopSystem

# Shop state
var in_shop: bool = false
var shop_items: Array = []
var has_visited_shop_this_floor: bool = false
const FOG_RADIUS := 6
const FOG_RADIUS_SQ := FOG_RADIUS * FOG_RADIUS

var map_data: TileMapData
var generator: DungeonGenerator
var player_pos: Vector2i
var current_floor: int = 1
var camera_offset: Vector2 = Vector2.ZERO

# Message log (replaces single message)
var message_log: Array = []  # Array of {text: String, age: float}
const MAX_LOG_MESSAGES := 5

# Player stats
var player_hp: int = 20
var player_max_hp: int = 20
var player_atk: int = 3
var player_def: int = 1
var kill_count: int = 0

# Base stats (before equipment)
var base_atk: int = 3
var base_def: int = 1
var base_max_hp: int = 20

# Equipment
var equipped_weapon: Item = null
var equipped_armor: Item = null
var equipped_accessory: Item = null
# Inventory UI state
var in_inventory: bool = false
var inventory_selected_slot: int = 0  # 0=weapon, 1=armor, 2=accessory
# Stats UI state
var in_stats: bool = false
var crit_chance: float = 0.05  # Base 5% crit
var crit_multiplier: float = 1.5

# Status effects
var poison_turns: int = 0
var burn_turns: int = 0
var slow_turns: int = 0
var bleed_stacks: int = 0  # Bleed: damage per turn, stacks
var poison_damage_flash: float = 0.0
var burn_damage_flash: float = 0.0
var bleed_damage_flash: float = 0.0

# XP & Leveling
var player_xp: int = 0
var player_level: int = 1
var levelup_flash_timer: float = 0.0

# Keys for secret rooms
var keys: int = 0

# Traps
var traps: Array = []  # Array of Trap

# Enemies
var enemies: Array = []  # Array of Enemy

# Items
var items: Array = []  # Array of Item
var gold_collected: int = 0
var shop_ui: ShopUI

# Score
var score: int = 0

# Fog of war
var revealed: Dictionary = {}
var explored: Dictionary = {}
var stairs_found: Dictionary = {}

# Game state
var game_over: bool = false
var damage_flash_timer: float = 0.0

# Boss floor state
var is_boss_floor: bool = false
var boss_defeated: bool = false
var boss_stairs_pos: Vector2i = Vector2i(-1, -1)

# Touch input
var touch_start: Vector2 = Vector2.ZERO
var is_touching: bool = false
const SWIPE_THRESHOLD := 30.0

# D-pad touch controls
const DPAD_BTN_SIZE := 56.0
const DPAD_GAP := 4.0
const DPAD_MARGIN_BOTTOM := 28.0
const DPAD_ALPHA := 0.35
const DPAD_PRESSED_ALPHA := 0.6
var dpad_pressed_dir: Vector2i = Vector2i.ZERO
var dpad_touch_index: int = -1
var dpad_repeat_timer: float = 0.0
const DPAD_REPEAT_DELAY := 0.28
const DPAD_REPEAT_RATE := 0.12
var dpad_repeat_started: bool = false

# Shop button for mobile
var shop_btn_rect: Rect2 = Rect2(0, 0, 60, 60)
var shop_btn_touch_index: int = -1


# Turn counter (for Golem/Lich mechanics)
var turn_count: int = 0

# Floating damage numbers
var floating_texts: Array = []  # Array of {pos: Vector2, text: String, age: float, color: Color, velocity: Vector2}

# Colors (will be modified by floor theme)
var color_wall: Color = Color(0.25, 0.15, 0.08)
var color_floor: Color = Color(0.2, 0.2, 0.22)
var color_stairs: Color = Color(0.0, 0.8, 0.8)
var color_player: Color = Color(0.2, 0.9, 0.2)
var color_bg: Color = Color(0.05, 0.05, 0.07)
var color_text: Color = Color(0.9, 0.9, 0.8)
var color_hud_bg: Color = Color(0.0, 0.0, 0.0, 0.7)
var color_fog: Color = Color(0.0, 0.0, 0.0)
var color_dim: float = 0.45

# Floor themes
enum FloorTheme { DUNGEON, CAVE, CRYPT, VOLCANIC, ICE, SHADOW }
var current_theme: FloorTheme = FloorTheme.DUNGEON

# Viewport
var viewport_w: int = 480
var viewport_h: int = 800

# Minimap
const MINIMAP_SIZE := 120
const MINIMAP_MARGIN := 8
var minimap_scale: float = 2.0

func _ready() -> void:
	# Initialize persistent data
	persistent_data = PersistentData.new()
	persistent_data.load()
	
	# Initialize shop system
	shop_system = ShopSystem.new()
	shop_system.initialize(persistent_data)
	# Create shop UI instance
	var shop_ui_scene = preload("res://scenes/shop.tscn")
	shop_ui = shop_ui_scene.instantiate()
	add_child(shop_ui)
	shop_ui.hide()
	
	# Connect shop signals
	shop_ui.item_purchased.connect(_on_shop_item_purchased)
	shop_ui.shop_closed.connect(_on_shop_closed)
	
	generator = DungeonGenerator.new()
	_apply_persistent_upgrades()
	_generate_floor()

func _apply_persistent_upgrades() -> void:
	# Apply permanent upgrades from persistent data
	base_max_hp = 20 + persistent_data.permanent_upgrades.get("max_hp_bonus", 0) * 5
	player_max_hp = base_max_hp
	player_hp = player_max_hp
	base_atk = 3 + persistent_data.permanent_upgrades.get("atk_bonus", 0)
	base_def = 1 + persistent_data.permanent_upgrades.get("def_bonus", 0)
	player_atk = base_atk
	player_def = base_def
	gold_collected = persistent_data.permanent_upgrades.get("starting_gold", 0)
	_recalculate_stats()

func _recalculate_stats() -> void:
	# Recalculate total stats from base + equipment
	player_atk = base_atk
	player_def = base_def
	player_max_hp = base_max_hp
	crit_chance = 0.05  # Base 5%
	
	if equipped_weapon:
		player_atk += equipped_weapon.atk_bonus
		player_def += equipped_weapon.def_bonus
		crit_chance += equipped_weapon.crit_bonus
	if equipped_armor:
		player_atk += equipped_armor.atk_bonus
		player_def += equipped_armor.def_bonus
		player_max_hp += equipped_armor.hp_bonus
	if equipped_accessory:
		player_atk += equipped_accessory.atk_bonus
		player_def += equipped_accessory.def_bonus
		player_max_hp += equipped_accessory.hp_bonus
		crit_chance += equipped_accessory.crit_bonus
	
	# Cap HP if it decreased
	if player_hp > player_max_hp:
		player_hp = player_max_hp
func _is_boss_floor_num(floor_num: int) -> bool:
	return floor_num % 5 == 0

func _is_shop_floor_num(floor_num: int) -> bool:
	# Shop appears every floor (except boss floors)
	return not _is_boss_floor_num(floor_num)

func _apply_floor_theme() -> void:
	# Cycle through themes every 5 floors
	var theme_index: int = (current_floor / 5) % 5
	match theme_index:
		0:  # Floors 1-5, 26-30, etc.
			current_theme = FloorTheme.DUNGEON
			color_wall = Color(0.25, 0.15, 0.08)
			color_floor = Color(0.2, 0.2, 0.22)
			color_bg = Color(0.05, 0.05, 0.07)
		1:  # Floors 6-10, 31-35, etc.
			current_theme = FloorTheme.CAVE
			color_wall = Color(0.3, 0.25, 0.2)
			color_floor = Color(0.15, 0.12, 0.1)
			color_bg = Color(0.02, 0.02, 0.03)
		2:  # Floors 11-15, 36-40, etc.
			current_theme = FloorTheme.CRYPT
			color_wall = Color(0.15, 0.15, 0.2)
			color_floor = Color(0.1, 0.1, 0.15)
			color_bg = Color(0.02, 0.02, 0.05)
		3:  # Floors 16-20, 41-45, etc.
			current_theme = FloorTheme.VOLCANIC
			color_wall = Color(0.35, 0.15, 0.1)
			color_floor = Color(0.25, 0.1, 0.08)
			color_bg = Color(0.1, 0.03, 0.02)
		4:  # Floors 21-25, 46-50, etc.
			current_theme = FloorTheme.ICE
			color_wall = Color(0.2, 0.25, 0.35)
			color_floor = Color(0.15, 0.2, 0.3)
			color_bg = Color(0.02, 0.05, 0.08)
func _get_xp_for_next_level() -> int:
	# Formula: 30 * level^1.5, rounded
	return roundi(30.0 * pow(float(player_level), 1.5))

func _check_level_up() -> void:
	var needed: int = _get_xp_for_next_level()
	while player_xp >= needed and player_level < 99:
		player_xp -= needed
		player_level += 1
		base_max_hp += 5
		player_max_hp = base_max_hp
		player_hp = player_max_hp  # Heal to full
		base_atk += 1
		player_atk = base_atk
		levelup_flash_timer = 1.5
		_add_log_message("LEVEL UP! Now level " + str(player_level) + "!")
		_recalculate_stats()
		needed = _get_xp_for_next_level()

func _add_log_message(msg: String) -> void:
	message_log.push_front({"text": msg, "age": 0.0})
	if message_log.size() > MAX_LOG_MESSAGES:
		message_log.resize(MAX_LOG_MESSAGES)

func _spawn_floating_text(pos: Vector2i, text: String, color: Color) -> void:
	var screen_pos := Vector2(
		float(pos.x * TILE_SIZE) + camera_offset.x + float(TILE_SIZE) / 2.0,
		float(pos.y * TILE_SIZE) + camera_offset.y + float(TILE_SIZE) / 2.0
	)
	floating_texts.append({
		"pos": screen_pos,
		"text": text,
		"age": 0.0,
		"color": color,
		"velocity": Vector2(randf_range(-20, 20), -60)
	})

func _update_floating_texts(delta: float) -> void:
	for i in range(floating_texts.size() - 1, -1, -1):
		var ft = floating_texts[i]
		ft.age += delta
		ft.pos += ft.velocity * delta
		ft.velocity.y += 80 * delta  # Gravity
		if ft.age > 1.0:
			floating_texts.remove_at(i)

func _generate_floor() -> void:
	is_boss_floor = _is_boss_floor_num(current_floor)
	var is_shop_floor: bool = _is_shop_floor_num(current_floor)
	boss_defeated = false
	boss_stairs_pos = Vector2i(-1, -1)
	turn_count = 0
	in_shop = false
	has_visited_shop_this_floor = false
	traps.clear()
	poison_turns = 0
	burn_turns = 0
	slow_turns = 0
	
	# Apply floor theme based on floor number
	_apply_floor_theme()
	
	if is_boss_floor:
		map_data = generator.generate_boss_floor()
		player_pos = generator.get_boss_player_start()
		revealed.clear()
		explored.clear()
		stairs_found.clear()
		_spawn_boss()
		items.clear()
		_update_visibility()
		_update_camera()
		_add_log_message("=== BOSS FLOOR " + str(current_floor) + " ===")
	elif is_shop_floor:
		# Generate a special shop floor with fewer enemies
		map_data = generator.generate(60, 60, true)
		player_pos = map_data.get_random_floor_tile()
		revealed.clear()
		explored.clear()
		stairs_found.clear()
		# Spawn fewer enemies on shop floors
		_spawn_enemies_shop_floor()
		_spawn_items()
		_spawn_traps()
		_spawn_secret_room_items()
		_update_visibility()
		_update_camera()
		_add_log_message("Floor " + str(current_floor) + " - Press S near gold tile for shop!")
	else:
		map_data = generator.generate(60, 60, false)
		player_pos = map_data.get_random_floor_tile()
		revealed.clear()
		explored.clear()
		stairs_found.clear()
		_spawn_enemies()
		_spawn_items()
		_spawn_traps()
		_spawn_secret_room_items()
		_update_visibility()
		_update_camera()
		_add_log_message("Floor " + str(current_floor))
	
	queue_redraw()

func _get_types_for_floor(floor_num: int) -> Array:
	var types: Array = []
	if floor_num >= 1:
		types.append(Enemy.Type.SLIME)
		types.append(Enemy.Type.BAT)
	if floor_num >= 3:
		types.append(Enemy.Type.SKELETON)
		types.append(Enemy.Type.SPIDER)
	if floor_num >= 4:
		types.append(Enemy.Type.WRAITH)
	if floor_num >= 5:
		types.append(Enemy.Type.ORC)
	if floor_num >= 6:
		types.append(Enemy.Type.FIRE_IMP)
	if floor_num >= 7:
		types.append(Enemy.Type.GHOST)
	if floor_num >= 8:
		types.append(Enemy.Type.GOLEM)
	if floor_num >= 9:
		types.append(Enemy.Type.MIMIC)
	if floor_num >= 10:
		types.append(Enemy.Type.VAMPIRE)
	if floor_num >= 11:
		types.append(Enemy.Type.TROLL)
	if floor_num >= 12:
		types.append(Enemy.Type.CRYSTAL_GOLEM)
	if floor_num >= 13:
		types.append(Enemy.Type.SHADOW)
	if floor_num >= 8:
		types.append(Enemy.Type.WISP)
	if floor_num >= 10:
		types.append(Enemy.Type.RAZOR_BEAST)
	if floor_num >= 11:
		types.append(Enemy.Type.DJINN)
	# Phase out weak enemies
	if floor_num > 3:
		types.erase(Enemy.Type.SLIME)
	if floor_num > 5:
		types.erase(Enemy.Type.BAT)
	return types

func _spawn_enemies() -> void:
	enemies.clear()
	var count: int = 3 + (randi() % 4)  # 3-6 enemies
	# Scale count with floor
	count += current_floor / 3
	count = mini(count, 10)
	var valid_types: Array = _get_types_for_floor(current_floor)
	if valid_types.is_empty():
		return

	var occupied: Dictionary = {}
	occupied[player_pos] = true
	for y in range(map_data.height):
		for x in range(map_data.width):
			if map_data.get_tile(x, y) == TileMapData.Tile.STAIRS_DOWN:
				occupied[Vector2i(x, y)] = true

	var attempts: int = 0
	while enemies.size() < count and attempts < 200:
		attempts += 1
		var pos: Vector2i = map_data.get_random_floor_tile()
		if occupied.has(pos):
			continue
		# Don't spawn too close to player
		var dist: int = absi(pos.x - player_pos.x) + absi(pos.y - player_pos.y)
		if dist < 5:
			continue
		var t: int = valid_types[randi() % valid_types.size()]
		var enemy: Enemy = Enemy.new()
		enemy.setup(t, pos)
		enemies.append(enemy)
		occupied[pos] = true

func _spawn_enemies_shop_floor() -> void:
	enemies.clear()
	var count: int = 1 + (randi() % 2)  # Only 1-2 enemies on shop floors
	# Scale count with floor but keep it low
	count += current_floor / 6
	count = mini(count, 4)
	
	var valid_types: Array = _get_types_for_floor(current_floor)
	if valid_types.is_empty():
		return

	var occupied: Dictionary = {}
	occupied[player_pos] = true
	
	for y in range(map_data.height):
		for x in range(map_data.width):
			if map_data.get_tile(x, y) == TileMapData.Tile.STAIRS_DOWN:
				occupied[Vector2i(x, y)] = true

	var attempts: int = 0
	while enemies.size() < count and attempts < 200:
		attempts += 1
		var pos: Vector2i = map_data.get_random_floor_tile()
		if occupied.has(pos):
			continue
		# Don't spawn too close to player
		var dist: int = absi(pos.x - player_pos.x) + absi(pos.y - player_pos.y)
		if dist < 5:
			continue
		var t: int = valid_types[randi() % valid_types.size()]
		var enemy: Enemy = Enemy.new()
		enemy.setup(t, pos)
		enemies.append(enemy)
		occupied[pos] = true
func _spawn_items() -> void:
	items.clear()
	
	# Base item types available on all floors
	var base_items: Array = [
		Item.Type.HEALTH_POTION,
		Item.Type.HEALTH_POTION,
		Item.Type.STRENGTH_POTION,
		Item.Type.GOLD,
		Item.Type.GOLD,
		Item.Type.KEY,
		Item.Type.BOMB
	]
	
	# Add floor-specific items
	if current_floor >= 3:
		base_items.append(Item.Type.SWORD)
	if current_floor >= 5:
		base_items.append(Item.Type.SHIELD)
		base_items.append(Item.Type.DAGGER)
	if current_floor >= 7:
		base_items.append(Item.Type.AXE)
	if current_floor >= 10:
		base_items.append(Item.Type.RING_POWER)
	if current_floor >= 12:
		base_items.append(Item.Type.AMULET_LIFE)
	if current_floor >= 15:
		base_items.append(Item.Type.TELEPORT_SCROLL)
	if current_floor >= 20:
		base_items.append(Item.Type.BLESSING_SCROLL)
	if current_floor >= 8:
		base_items.append(Item.Type.GREATSWORD)
	if current_floor >= 6:
		base_items.append(Item.Type.SPEAR)
	if current_floor >= 14:
		base_items.append(Item.Type.RING_VAMPIRE)
	if current_floor >= 16:
		base_items.append(Item.Type.AMULET_FURY)
	if current_floor >= 9:
		base_items.append(Item.Type.FIRE_BOMB)
	if current_floor >= 11:
		base_items.append(Item.Type.FROST_SCROLL)
	if current_floor >= 13:
		base_items.append(Item.Type.SHADOW_STEP)
	# Spawn 3-6 items per floor
	var item_count: int = 3 + (randi() % 4)
	
	# Create a list of walkable positions
	var walkable_positions: Array[Vector2i] = []
	for y in range(map_data.height):
		for x in range(map_data.width):
			if map_data.is_walkable(x, y) and Vector2i(x, y) != player_pos:
				walkable_positions.append(Vector2i(x, y))
	
	if walkable_positions.size() == 0:
		return
	
	walkable_positions.shuffle()
	
	# Spawn items at random walkable positions
	for i in range(mini(item_count, walkable_positions.size())):
		var item_pos: Vector2i = walkable_positions[i]
		var item_type: Item.Type = base_items[randi() % base_items.size()]
		var item: Item = Item.new()
		item.setup(item_type, item_pos)
		items.append(item)

func _spawn_boss() -> void:
	enemies.clear()
	items.clear()
	var boss_pos: Vector2i = generator.get_boss_room_center()
	var boss: Enemy = Enemy.new()

	if current_floor <= 5:
		boss.setup(Enemy.Type.BOSS_SLIME, boss_pos)
	elif current_floor <= 10:
		boss.setup(Enemy.Type.BOSS_LICH, boss_pos)
	else:
		boss.setup(Enemy.Type.BOSS_DRAGON, boss_pos)

	enemies.append(boss)



func _spawn_traps() -> void:
	traps.clear()
	# More traps on higher floors
	var trap_count: int = 1 + current_floor / 4
	trap_count = mini(trap_count, 5)
	
	if trap_count < 1:
		return
	
	var trap_positions: Array[Vector2i] = generator.get_trap_positions(trap_count, current_floor)
	
	for pos in trap_positions:
		var trap_types: Array = [Trap.Type.SPIKES, Trap.Type.SPIKES, Trap.Type.POISON_DART]
		# Add themed traps based on floor theme
		match current_theme:
			FloorTheme.DUNGEON:
				if current_floor >= 5:
					trap_types.append(Trap.Type.FIRE_VENT)
			FloorTheme.CAVE:
				trap_types.append(Trap.Type.SPIKES)
			FloorTheme.CRYPT:
				if current_floor >= 8:
					trap_types.append(Trap.Type.SHADOW_PIT)
			FloorTheme.VOLCANIC:
				trap_types.append(Trap.Type.LAVA_CRACK)
				trap_types.append(Trap.Type.FIRE_VENT)
			FloorTheme.ICE:
				trap_types.append(Trap.Type.ICE_PATCH)
		# Generic traps for all themes
		if current_floor >= 8:
			trap_types.append(Trap.Type.TELEPORT)
		if current_floor >= 12:
			trap_types.append(Trap.Type.SPIRIT_WISP)
		# Themed traps based on floor theme
		match current_theme:
			FloorTheme.ICE:
				if current_floor >= 6:
					trap_types.append(Trap.Type.ICE_PATCH)
			FloorTheme.VOLCANIC:
				if current_floor >= 16:
					trap_types.append(Trap.Type.LAVA_CRACK)
			FloorTheme.SHADOW:
				if current_floor >= 21:
					trap_types.append(Trap.Type.SHADOW_PIT)
					trap_types.append(Trap.Type.SPIRIT_WISP)
			FloorTheme.CRYPT:
				if current_floor >= 11:
					trap_types.append(Trap.Type.SPIRIT_WISP)
		
		var trap: Trap = Trap.new()
		trap.setup(trap_types[randi() % trap_types.size()], pos)
		traps.append(trap)

func _spawn_secret_room_items() -> void:
	# Spawn bonus items in secret rooms
	var secret_positions: Array[Vector2i] = generator.get_secret_room_positions()
	
	for secret_pos in secret_positions:
		# Spawn 2-3 good items in each secret room
		var item_count: int = 2 + randi() % 2
		var offsets: Array[Vector2i] = [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), 
			Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1)
		]
		offsets.shuffle()
		
		var good_items: Array = [
			Item.Type.STRENGTH_POTION, Item.Type.STRENGTH_POTION,
			Item.Type.SHIELD_SCROLL,
			Item.Type.HEALTH_POTION, Item.Type.HEALTH_POTION,
			Item.Type.GOLD, Item.Type.GOLD, Item.Type.GOLD,
			Item.Type.KEY, Item.Type.BOMB
		]
		
		for i in range(mini(item_count, offsets.size())):
			var item_pos: Vector2i = secret_pos + offsets[i]
			if map_data.get_tile(item_pos.x, item_pos.y) == TileMapData.Tile.SECRET_ROOM:
				var item: Item = Item.new()
				item.setup(good_items[randi() % good_items.size()], item_pos)
				items.append(item)

func _update_visibility() -> void:
	revealed.clear()
	var px: int = player_pos.x
	var py: int = player_pos.y
	for dy in range(-FOG_RADIUS, FOG_RADIUS + 1):
		for dx in range(-FOG_RADIUS, FOG_RADIUS + 1):
			if dx * dx + dy * dy <= FOG_RADIUS_SQ:
				var tx: int = px + dx
				var ty: int = py + dy
				if tx >= 0 and tx < map_data.width and ty >= 0 and ty < map_data.height:
					var tpos: Vector2i = Vector2i(tx, ty)
					revealed[tpos] = true
					explored[tpos] = true
					if map_data.get_tile(tx, ty) == TileMapData.Tile.STAIRS_DOWN:
						stairs_found[tpos] = true

func _is_visible(pos: Vector2i) -> bool:
	return revealed.has(pos)

func _is_explored(pos: Vector2i) -> bool:
	return explored.has(pos)

func _calculate_score() -> int:
	return kill_count * 10 + gold_collected + current_floor * 5


# === D-PAD HELPERS ===
func _get_dpad_center() -> Vector2:
	var cx: float = 90.0
	var cy: float = float(viewport_h) - DPAD_BTN_SIZE - DPAD_MARGIN_BOTTOM - DPAD_GAP
	return Vector2(cx, cy)

func _get_dpad_rects() -> Dictionary:
	var c: Vector2 = _get_dpad_center()
	var s: float = DPAD_BTN_SIZE
	var g: float = DPAD_GAP
	return {
		"up": Rect2(c.x - s / 2.0, c.y - s * 1.5 - g, s, s),
		"down": Rect2(c.x - s / 2.0, c.y + s * 0.5 + g, s, s),
		"left": Rect2(c.x - s * 1.5 - g, c.y - s / 2.0, s, s),
		"right": Rect2(c.x + s * 0.5 + g, c.y - s / 2.0, s, s),
	}

func _dpad_hit_test(pos: Vector2) -> Vector2i:
	var rects: Dictionary = _get_dpad_rects()
	if rects["up"].has_point(pos):
		return Vector2i(0, -1)
	if rects["down"].has_point(pos):
		return Vector2i(0, 1)
	if rects["left"].has_point(pos):
		return Vector2i(-1, 0)
	if rects["right"].has_point(pos):
		return Vector2i(1, 0)
	return Vector2i.ZERO

func _process(delta: float) -> void:
	# Age log messages
	var needs_redraw: bool = false
	for i in range(message_log.size()):
		message_log[i]["age"] += delta
	if levelup_flash_timer > 0:
		levelup_flash_timer -= delta
		if levelup_flash_timer <= 0:
			levelup_flash_timer = 0.0
		needs_redraw = true
	if damage_flash_timer > 0:
		damage_flash_timer -= delta
		if damage_flash_timer <= 0:
			damage_flash_timer = 0.0
		needs_redraw = true
	# Update floating texts
	if floating_texts.size() > 0:
		_update_floating_texts(delta)
		needs_redraw = true
	# D-pad hold repeat
		damage_flash_timer -= delta
		if damage_flash_timer <= 0:
			damage_flash_timer = 0.0
		needs_redraw = true
	# D-pad hold repeat
	if dpad_pressed_dir != Vector2i.ZERO and not game_over:
		dpad_repeat_timer += delta
		if not dpad_repeat_started:
			if dpad_repeat_timer >= DPAD_REPEAT_DELAY:
				dpad_repeat_started = true
				dpad_repeat_timer = 0.0
				_try_move(dpad_pressed_dir)
				needs_redraw = true
		else:
			if dpad_repeat_timer >= DPAD_REPEAT_RATE:
				dpad_repeat_timer = 0.0
				_try_move(dpad_pressed_dir)
				needs_redraw = true
	if needs_redraw:
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		var restart: bool = false
		if event is InputEventKey and event.is_pressed():
			restart = true
		elif event is InputEventScreenTouch:
			var te: InputEventScreenTouch = event as InputEventScreenTouch
			if not te.pressed:
				restart = true
		if restart:
			_restart_game()
		return
	
	# Shop key (S)
	if event is InputEventKey and event.is_pressed():
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_S and _is_shop_floor_num(current_floor) and not has_visited_shop_this_floor:
			_show_shop()
			return
	# Inventory key (I)
	if event is InputEventKey and event.is_pressed():
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_I:
			in_inventory = !in_inventory
			return
	# Stats key (C)
	if event is InputEventKey and event.is_pressed():
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_C:
			in_stats = !in_stats
			return

	# Handle stats screen
	if in_stats:
		if event is InputEventKey and event.is_pressed():
			var key_event: InputEventKey = event as InputEventKey
			if key_event.keycode == KEY_C or key_event.keycode == KEY_ESCAPE:
				in_stats = false
				return
		
		# Don't process normal movement when in stats
		return
	
	# Handle inventory navigation and actions
	if in_inventory:
		if event is InputEventKey and event.is_pressed():
			var key_event: InputEventKey = event as InputEventKey
			match key_event.keycode:
				KEY_UP:
					inventory_selected_slot = maxi(0, inventory_selected_slot - 1)
					return
				KEY_DOWN:
					inventory_selected_slot = mini(2, inventory_selected_slot + 1)
					return
				KEY_SPACE:
					# Unequip selected item
					match inventory_selected_slot:
						0:  # Weapon
							if equipped_weapon:
								equipped_weapon.pos = player_pos
								equipped_weapon.collected = false
								items.append(equipped_weapon)
								equipped_weapon = null
								_add_log_message("Unequipped weapon!")
						1:  # Armor
							if equipped_armor:
								equipped_armor.pos = player_pos
								equipped_armor.collected = false
								items.append(equipped_armor)
								equipped_armor = null
								_add_log_message("Unequipped armor!")
						2:  # Accessory
							if equipped_accessory:
								equipped_accessory.pos = player_pos
								equipped_accessory.collected = false
								items.append(equipped_accessory)
								equipped_accessory = null
								_add_log_message("Unequipped accessory!")
					_recalculate_stats()
					return
				KEY_ESCAPE:
					in_inventory = false
					return
		
		# Don't process normal movement when in inventory
		return
	
	var dir: Vector2i = Vector2i.ZERO

	# Keyboard
	if event.is_action_pressed("move_up"):
		dir = Vector2i(0, -1)
	elif event.is_action_pressed("move_down"):
		dir = Vector2i(0, 1)
	elif event.is_action_pressed("move_left"):
		dir = Vector2i(-1, 0)
	elif event.is_action_pressed("move_right"):
		dir = Vector2i(1, 0)


	# D-pad touch buttons
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			var dpad_dir: Vector2i = _dpad_hit_test(touch_event.position)
			if dpad_dir != Vector2i.ZERO:
				dir = dpad_dir
				dpad_pressed_dir = dpad_dir
				dpad_touch_index = touch_event.index
				dpad_repeat_timer = 0.0
				dpad_repeat_started = false
				queue_redraw()
			else:
				# Shop button touch
				if _is_shop_floor_num(current_floor) and not has_visited_shop_this_floor and not in_shop:
					if shop_btn_rect.has_point(touch_event.position):
						_show_shop()
						return
				# Close inventory when touching outside (mobile)
				if in_inventory:
					in_inventory = false
					return
				# Close stats when touching outside (mobile)
				if in_stats:
					in_stats = false
					return
				touch_start = touch_event.position
				is_touching = true
		else:
			if touch_event.index == dpad_touch_index:
				dpad_pressed_dir = Vector2i.ZERO
				dpad_touch_index = -1
				dpad_repeat_timer = 0.0
				dpad_repeat_started = false
				queue_redraw()
			is_touching = false
	elif event is InputEventScreenDrag:
		if dpad_touch_index >= 0 and event is InputEventScreenDrag:
			var drag_ev: InputEventScreenDrag = event as InputEventScreenDrag
			if drag_ev.index == dpad_touch_index:
				var new_dir: Vector2i = _dpad_hit_test(drag_ev.position)
				if new_dir != dpad_pressed_dir:
					if new_dir != Vector2i.ZERO:
						dpad_pressed_dir = new_dir
						dpad_repeat_timer = 0.0
						dpad_repeat_started = false
						dir = new_dir
					else:
						dpad_pressed_dir = Vector2i.ZERO
						dpad_touch_index = -1
					queue_redraw()
		elif is_touching:
			var drag_event: InputEventScreenDrag = event as InputEventScreenDrag
			var delta_pos: Vector2 = drag_event.position - touch_start
			if delta_pos.length() > SWIPE_THRESHOLD:
				is_touching = false
				if abs(delta_pos.x) > abs(delta_pos.y):
					if delta_pos.x > 0:
						dir = Vector2i(1, 0)
					else:
						dir = Vector2i(-1, 0)
				else:
					if delta_pos.y > 0:
						dir = Vector2i(0, 1)
					else:
						dir = Vector2i(0, -1)

	if dir != Vector2i.ZERO and not in_inventory and not in_stats:
		_try_move(dir)


func _process_status_effects() -> void:
	# Poison damage
	if poison_turns > 0:
		var poison_dmg: int = 1
		player_hp -= poison_dmg
		poison_turns -= 1
		poison_damage_flash = 0.3
		_add_log_message("Poison deals " + str(poison_dmg) + " damage! (" + str(poison_turns) + " turns left)")
		if player_hp <= 0:
			player_hp = 0
			game_over = true
			score = _calculate_score()
			_save_on_death()
	
	# Burn damage
	if burn_turns > 0:
		var burn_dmg: int = 2
		player_hp -= burn_dmg
		burn_turns -= 1
		burn_damage_flash = 0.3
		_add_log_message("Fire burns for " + str(burn_dmg) + " damage! (" + str(burn_turns) + " turns left)")
		if player_hp <= 0:
			player_hp = 0
			game_over = true
			score = _calculate_score()
			_save_on_death()
	
	# Slow effect
	if slow_turns > 0:
		slow_turns -= 1
		if slow_turns == 0:
			_add_log_message("Slow effect wore off!")
	
	# Bleed damage (stacks)
	if bleed_stacks > 0:
		var bleed_dmg: int = bleed_stacks
		player_hp -= bleed_dmg
		bleed_damage_flash = 0.3
		_add_log_message("Bleeding for " + str(bleed_dmg) + " damage! (" + str(bleed_stacks) + " stacks)")
		bleed_stacks = maxi(0, bleed_stacks - 1)  # Reduce by 1 each turn
		if player_hp <= 0:
			player_hp = 0
			game_over = true
			score = _calculate_score()
			_save_on_death()


func _boss_slime_split(boss: Enemy) -> void:
	_add_log_message("Giant Slime splits into smaller slimes!")
	# Spawn 2 regular slimes near the boss
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var spawned: int = 0
	for offset in offsets:
		if spawned >= 2:
			break
		var spos: Vector2i = boss.pos + offset
		if map_data.is_walkable(spos.x, spos.y) and _get_enemy_at(spos) == null and spos != player_pos:
			var slime: Enemy = Enemy.new()
			slime.setup(Enemy.Type.SLIME, spos)
			enemies.append(slime)
			spawned += 1

func _on_boss_defeated() -> void:
	boss_defeated = true
	_add_log_message("Boss defeated! Stairs appear!")
	# Place stairs in center of boss room
	boss_stairs_pos = generator.get_boss_room_center()
	map_data.set_tile(boss_stairs_pos.x, boss_stairs_pos.y, TileMapData.Tile.STAIRS_DOWN)
	stairs_found[boss_stairs_pos] = true
	# Drop guaranteed strength potion near boss center
	var drop_pos: Vector2i = boss_stairs_pos + Vector2i(1, 0)
	if map_data.is_walkable(drop_pos.x, drop_pos.y):
		var potion: Item = Item.new()
		potion.setup(Item.Type.STRENGTH_POTION, drop_pos)
		items.append(potion)

func _enemy_turn() -> void:
	# Process enemies; handle multi-action bosses
	var enemy_list: Array = enemies.duplicate()
	for enemy in enemy_list:
		if not enemy.alive:
			continue
		var actions: int = enemy.actions_per_turn
		for _a in range(actions):
			if not enemy.alive:
				break
			_process_single_enemy_turn(enemy)

func _process_single_enemy_turn(enemy: Enemy) -> void:
	# Golem: only moves every other turn
	if enemy.type == Enemy.Type.GOLEM:
		enemy.move_cooldown += 1
		if enemy.move_cooldown % 2 == 1:
			return  # Skip this turn

	# Lich: summon skeleton every 3 turns
	if enemy.type == Enemy.Type.BOSS_LICH:
		enemy.summon_timer += 1
		if enemy.summon_timer >= 3:
			enemy.summon_timer = 0
			_lich_summon(enemy)

	# Necromancer: resurrect dead enemies every 4 turns
	if enemy.can_resurrect:
		enemy.summon_timer += 1
		if enemy.summon_timer >= 4:
			enemy.summon_timer = 0
			_try_resurrect(enemy)
	var dist: int = absi(enemy.pos.x - player_pos.x) + absi(enemy.pos.y - player_pos.y)

	# Fire Imp ranged attack: if player is 2-3 tiles away in cardinal direction
	if enemy.ranged_attack and dist >= 2 and dist <= 3:
		if _try_ranged_attack(enemy):
			return

	var move_dir: Vector2i = Vector2i.ZERO

	if dist <= 5:
		move_dir = _get_chase_dir(enemy.pos, player_pos, enemy.phase_through_walls)
	else:
		if randf() < 0.5:
			var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			move_dir = dirs[randi() % 4]

	if move_dir == Vector2i.ZERO:
		return

	var new_pos: Vector2i = enemy.pos + move_dir

	# Check if new_pos is the player (bump attack)
	if new_pos == player_pos:
		_enemy_attack(enemy)
		return

	# Wraith can phase through walls
	if enemy.phase_through_walls:
		if new_pos.x >= 0 and new_pos.x < map_data.width and new_pos.y >= 0 and new_pos.y < map_data.height:
			if _get_enemy_at(new_pos) == null:
				enemy.pos = new_pos
	else:
		if map_data.is_walkable(new_pos.x, new_pos.y) and _get_enemy_at(new_pos) == null:
			enemy.pos = new_pos



func _lich_summon(lich: Enemy) -> void:
	# Summon a skeleton near the lich
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]
	for offset in offsets:
		var spos: Vector2i = lich.pos + offset
		if map_data.is_walkable(spos.x, spos.y) and _get_enemy_at(spos) == null and spos != player_pos:
			var skel: Enemy = Enemy.new()
			skel.setup(Enemy.Type.SKELETON, spos)
			enemies.append(skel)
			_add_log_message("Lich summons a Skeleton!")
			return



func _try_resurrect(necro: Enemy) -> void:
	# Find a dead enemy position and resurrect as skeleton
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]
	for offset in offsets:
		var spos: Vector2i = necro.pos + offset
		if map_data.is_walkable(spos.x, spos.y) and _get_enemy_at(spos) == null and spos != player_pos:
			var skel: Enemy = Enemy.new()
			skel.setup(Enemy.Type.SKELETON, spos)
			enemies.append(skel)
			_add_log_message("Necromancer raises a Skeleton!")
			return



func _get_chase_dir(from: Vector2i, to: Vector2i, can_phase: bool = false) -> Vector2i:
	var dx: int = to.x - from.x
	var dy: int = to.y - from.y
	var dir: Vector2i
	if absi(dx) >= absi(dy):
		if dx > 0:
			dir = Vector2i(1, 0)
		elif dx < 0:
			dir = Vector2i(-1, 0)
		else:
			dir = Vector2i.ZERO
	else:
		if dy > 0:
			dir = Vector2i(0, 1)
		elif dy < 0:
			dir = Vector2i(0, -1)
		else:
			dir = Vector2i.ZERO

	var test: Vector2i = from + dir
	if can_phase:
		if test.x >= 0 and test.x < map_data.width and test.y >= 0 and test.y < map_data.height:
			return dir
	else:
		if map_data.is_walkable(test.x, test.y):
			return dir

	# Try the other axis
	var alt_dir: Vector2i
	if dir.x != 0:
		if dy > 0:
			alt_dir = Vector2i(0, 1)
		elif dy < 0:
			alt_dir = Vector2i(0, -1)
		else:
			alt_dir = Vector2i.ZERO
	else:
		if dx > 0:
			alt_dir = Vector2i(1, 0)
		elif dx < 0:
			alt_dir = Vector2i(-1, 0)
		else:
			alt_dir = Vector2i.ZERO

	if alt_dir != Vector2i.ZERO:
		var alt_test: Vector2i = from + alt_dir
		if can_phase:
			if alt_test.x >= 0 and alt_test.x < map_data.width and alt_test.y >= 0 and alt_test.y < map_data.height:
				return alt_dir
		else:
			if map_data.is_walkable(alt_test.x, alt_test.y):
				return alt_dir

	return Vector2i.ZERO


func _try_ranged_attack(enemy: Enemy) -> bool:
	# Fire Imp ranged attack - check if player is in cardinal direction
	var dx: int = player_pos.x - enemy.pos.x
	var dy: int = player_pos.y - enemy.pos.y
	
	# Must be in cardinal direction (not diagonal)
	if dx != 0 and dy != 0:
		return false
	
	# Check line of sight
	var check_pos: Vector2i = enemy.pos
	var step: Vector2i = Vector2i(signi(dx), signi(dy))
	while check_pos != player_pos:
		check_pos += step
		if not map_data.is_walkable(check_pos.x, check_pos.y):
			return false  # Blocked by wall
	
	# Perform ranged attack
	var dmg: int = maxi(1, enemy.atk - player_def)
	player_hp -= dmg
	damage_flash_timer = 0.3
	_spawn_floating_text(player_pos, "-" + str(dmg), Color(1.0, 0.2, 0.2))
	_add_log_message(enemy.name_str + " fires at you for " + str(dmg) + " damage!")
	
	if player_hp <= 0:
		player_hp = 0
		game_over = true
		_add_log_message("You died!")
		_save_on_death()
	return true


func _enemy_attack(enemy: Enemy) -> void:
	var dmg: int = maxi(1, enemy.atk - player_def)
	player_hp -= dmg
	damage_flash_timer = 0.3
	_spawn_floating_text(player_pos, "-" + str(dmg), Color(1.0, 0.2, 0.2))
	_add_log_message(enemy.name_str + " hits you for " + str(dmg) + " damage!")
	
	# Razor Beast applies bleed
	if enemy.type == Enemy.Type.RAZOR_BEAST:
		bleed_stacks += 2
		_add_log_message("You're bleeding! (+" + str(2) + " stacks)")
	
	if player_hp <= 0:
		player_hp = 0
		game_over = true
		_add_log_message("You died!")
		_save_on_death()


func _get_enemy_at(pos: Vector2i) -> Enemy:
	for enemy in enemies:
		if enemy.alive and enemy.pos == pos:
			return enemy
	return null

func _restart_game() -> void:
	game_over = false
	current_floor = 1
	player_hp = 20
	player_max_hp = 20
	player_atk = 3
	player_def = 1
	kill_count = 0
	gold_collected = 0
	score = 0
	player_xp = 0
	player_level = 1
	levelup_flash_timer = 0.0
	damage_flash_timer = 0.0
	message_log.clear()
	is_boss_floor = false
	boss_defeated = false
	turn_count = 0
	in_shop = false
	has_visited_shop_this_floor = false
	_generate_floor()
# === SHOP HANDLERS ===

func _show_shop() -> void:
	if not _is_shop_floor_num(current_floor):
		return
	
	if has_visited_shop_this_floor:
		_add_log_message("You've already visited the shop this floor.")
		return
	
	has_visited_shop_this_floor = true
	
	# Calculate total gold available (collected + persistent)
	var total_gold: int = gold_collected + persistent_data.total_gold_earned
	
	# Get random shop items
	shop_items = shop_system.get_random_shop_items(3)
	
	# Show shop UI
	shop_ui.show_shop(total_gold, shop_items)

func _on_shop_item_purchased(item_type: int) -> void:
	# Apply item effects based on type
	match item_type:
		ShopSystem.ShopItemType.HEALTH_POTION:
			var heal: int = mini(8, player_max_hp - player_hp)
			player_hp += heal
			_add_log_message("Used Health Potion! +" + str(heal) + " HP")
			
		ShopSystem.ShopItemType.STRENGTH_POTION:
			player_atk += 1
			_add_log_message("Used Strength Potion! +1 ATK")
			
		ShopSystem.ShopItemType.SHIELD_SCROLL:
			player_def += 1
			_add_log_message("Used Shield Scroll! +1 DEF")
			
		ShopSystem.ShopItemType.GOLD_BAG:
			gold_collected += 20
			_add_log_message("Got Gold Bag! +20 Gold")
			
		ShopSystem.ShopItemType.REVIVAL_AMULET:
			# Store revival amulet in persistent data for later use
			persistent_data.permanent_upgrades["revival_amulet"] = true
			_add_log_message("Bought Revival Amulet! Will revive you if you die.")
			
		ShopSystem.ShopItemType.TELEPORT_SCROLL:
			# Teleport to stairs immediately
			_teleport_to_stairs()
			
		ShopSystem.ShopItemType.BLESSING_SCROLL:
			player_xp += 50
			_add_log_message("Used Blessing Scroll! +50 XP")
			_check_level_up()
	
	# Update score and redraw
	score = _calculate_score()
	queue_redraw()

func _on_shop_closed() -> void:
	# Save any gold spent to persistent data
	# The shop UI handles gold deduction, so we need to sync with persistent data
	var current_total_gold: int = shop_ui.current_gold
	persistent_data.total_gold_earned = maxi(0, current_total_gold - gold_collected)
	persistent_data.save()
	
	# Continue gameplay
	queue_redraw()

func _teleport_to_stairs() -> void:
	# Find stairs position
	var stairs_pos: Vector2i = Vector2i(-1, -1)
	for y in range(map_data.height):
		for x in range(map_data.width):
			if map_data.get_tile(x, y) == TileMapData.Tile.STAIRS_DOWN:
				stairs_pos = Vector2i(x, y)
				break
		if stairs_pos.x != -1:
			break
	
	if stairs_pos.x != -1:
		player_pos = stairs_pos
		_update_visibility()
		_update_camera()
		_add_log_message("Teleported to stairs!")
		queue_redraw()
	else:
		_add_log_message("No stairs found!")

# Save player progress on death
func _save_on_death() -> void:
	# Add collected gold to persistent total
	persistent_data.total_gold_earned += gold_collected
	gold_collected = 0
	
	# Update highest floor reached
	persistent_data.update_highest_floor(current_floor)
	
	# Increment games played
	persistent_data.games_played += 1
	
	# Save everything
	persistent_data.save()

func _update_camera() -> void:
	camera_offset = Vector2(
		float(viewport_w) / 2.0 - float(player_pos.x * TILE_SIZE) - float(TILE_SIZE) / 2.0,
		float(viewport_h) / 2.0 - float(player_pos.y * TILE_SIZE) - float(TILE_SIZE) / 2.0
	)

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, viewport_w, viewport_h), color_bg)

	# Boss floor red tint on background
	if is_boss_floor and not boss_defeated:
		draw_rect(Rect2(0, 0, viewport_w, viewport_h), Color(0.15, 0.0, 0.0, 0.3))

	# Calculate visible tile range
	var start_x: int = int(-camera_offset.x / float(TILE_SIZE)) - 1
	var start_y: int = int(-camera_offset.y / float(TILE_SIZE)) - 1
	var end_x: int = start_x + int(float(viewport_w) / float(TILE_SIZE)) + 3
	var end_y: int = start_y + int(float(viewport_h) / float(TILE_SIZE)) + 3

	start_x = maxi(start_x, 0)
	start_y = maxi(start_y, 0)
	end_x = mini(end_x, map_data.width)
	end_y = mini(end_y, map_data.height)

	# Draw tiles (with fog of war)
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var tpos: Vector2i = Vector2i(x, y)
			var visible: bool = _is_visible(tpos)
			var was_explored: bool = _is_explored(tpos)

			if not visible and not was_explored:
				continue

			var tile: int = map_data.get_tile(x, y)
			var rect: Rect2 = Rect2(
				float(x * TILE_SIZE) + camera_offset.x,
				float(y * TILE_SIZE) + camera_offset.y,
				float(TILE_SIZE - 1),
				float(TILE_SIZE - 1)
			)

			var tile_color: Color
			if tile == TileMapData.Tile.WALL:
				tile_color = color_wall
			elif tile == TileMapData.Tile.FLOOR:
				tile_color = color_floor
			elif tile == TileMapData.Tile.STAIRS_DOWN:
				if stairs_found.has(tpos):
					tile_color = color_stairs
				else:
					tile_color = color_floor
			elif tile == TileMapData.Tile.DOOR:
				tile_color = Color(0.6, 0.4, 0.1)
			elif tile == TileMapData.Tile.SHOP:
				tile_color = Color(0.8, 0.7, 0.2)  # Gold/yellow color for shop
			else:
				tile_color = color_floor

			if not visible:
				tile_color = Color(
					tile_color.r * color_dim,
					tile_color.g * color_dim,
					tile_color.b * color_dim
				)

			draw_rect(rect, tile_color)

	# Draw items (only if visible, not collected)
	for item in items:
		if item.collected:
			continue
		if not _is_visible(item.pos):
			continue
		var ix: float = float(item.pos.x * TILE_SIZE) + camera_offset.x
		var iy: float = float(item.pos.y * TILE_SIZE) + camera_offset.y
		var icx: float = ix + float(TILE_SIZE) / 2.0
		var icy: float = iy + float(TILE_SIZE) / 2.0
		var icolor: Color = item.get_color()

		match item.type:
			Item.Type.HEALTH_POTION:
				var s: float = float(TILE_SIZE) * 0.12
				var l: float = float(TILE_SIZE) * 0.3
				draw_rect(Rect2(icx - s, icy - l, s * 2.0, l * 2.0), icolor)
				draw_rect(Rect2(icx - l, icy - s, l * 2.0, s * 2.0), icolor)
			Item.Type.STRENGTH_POTION:
				var s: float = float(TILE_SIZE) * 0.25
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(icx, icy - s * 1.2),
					Vector2(icx + s, icy + s * 0.4),
					Vector2(icx + s * 0.3, icy + s * 0.4),
					Vector2(icx + s * 0.3, icy + s * 1.2),
					Vector2(icx - s * 0.3, icy + s * 1.2),
					Vector2(icx - s * 0.3, icy + s * 0.4),
					Vector2(icx - s, icy + s * 0.4)
				])
				draw_colored_polygon(pts, icolor)
			Item.Type.GREATSWORD:
				var s: float = float(TILE_SIZE) * 0.35
				# Large blade
				draw_rect(Rect2(icx - s * 0.15, icy - s * 0.9, s * 0.3, s * 1.4), icolor)
				# Cross guard
				draw_rect(Rect2(icx - s * 0.4, icy + s * 0.4, s * 0.8, s * 0.15), icolor)
				# Handle
				draw_rect(Rect2(icx - s * 0.1, icy + s * 0.55, s * 0.2, s * 0.35), Color(0.4, 0.25, 0.15))
			Item.Type.SPEAR:
				var s: float = float(TILE_SIZE) * 0.35
				# Shaft
				draw_rect(Rect2(icx - s * 0.08, icy - s * 0.8, s * 0.16, s * 1.6), Color(0.5, 0.35, 0.2))
				# Spearhead
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(icx, icy - s * 1.1),
					Vector2(icx + s * 0.2, icy - s * 0.7),
					Vector2(icx - s * 0.2, icy - s * 0.7)
				])
				draw_colored_polygon(pts, icolor)
			Item.Type.RING_VAMPIRE:
				var s: float = float(TILE_SIZE) * 0.25
				draw_circle(Vector2(icx, icy), s * 0.8, icolor)
				draw_circle(Vector2(icx, icy), s * 0.5, Color(0.1, 0.05, 0.1))  # Dark center
				# Red gem
				draw_circle(Vector2(icx, icy - s * 0.3), s * 0.15, Color(0.9, 0.1, 0.2))
			Item.Type.AMULET_FURY:
				var s: float = float(TILE_SIZE) * 0.25
				# Chain
				draw_rect(Rect2(icx - s * 0.1, icy - s * 0.9, s * 0.2, s * 0.3), Color(0.7, 0.6, 0.3))
				# Amulet body
				draw_circle(Vector2(icx, icy), s * 0.7, icolor)
				# Flame symbol inside
				var flame_pts: PackedVector2Array = PackedVector2Array([
					Vector2(icx, icy - s * 0.4),
					Vector2(icx + s * 0.2, icy + s * 0.3),
					Vector2(icx, icy + s * 0.1),
					Vector2(icx - s * 0.2, icy + s * 0.3)
				])
				draw_colored_polygon(flame_pts, Color(1.0, 0.5, 0.1))

	# Draw enemies
	for enemy in enemies:
		if not enemy.alive:
			continue
		if not _is_visible(enemy.pos):
			continue
		var ex: float = float(enemy.pos.x * TILE_SIZE) + camera_offset.x
		var ey: float = float(enemy.pos.y * TILE_SIZE) + camera_offset.y
		var ecx: float = ex + float(TILE_SIZE) / 2.0
		var ecy: float = ey + float(TILE_SIZE) / 2.0
		var ecolor: Color = enemy.get_color()

		if ecx < -TILE_SIZE or ecx > viewport_w + TILE_SIZE:
			continue
		if ecy < -TILE_SIZE or ecy > viewport_h + TILE_SIZE:
			continue

		match enemy.type:
			Enemy.Type.SLIME:
				# Blob shape - amorphous puddle
				# Blob shape - amorphous puddle with wavy bottom
				var s: float = float(TILE_SIZE) * 0.35
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s * 0.8),
					Vector2(ecx + s * 0.8, ecy - s * 0.4),
					Vector2(ecx + s * 0.6, ecy + s * 0.3),
					Vector2(ecx + s * 0.2, ecy + s * 0.6),
					Vector2(ecx - s * 0.2, ecy + s * 0.6),
					Vector2(ecx - s * 0.6, ecy + s * 0.3),
					Vector2(ecx - s * 0.8, ecy - s * 0.4)
				])
				draw_colored_polygon(pts, ecolor)
				# Highlight (eye)
				draw_circle(Vector2(ecx - s * 0.2, ecy - s * 0.3), s * 0.15, Color(0.9, 1.0, 0.9, 0.6))
				# Mouth
				draw_line(Vector2(ecx - s * 0.2, ecy + s * 0.1), Vector2(ecx + s * 0.2, ecy + s * 0.1), Color(0.2, 0.2, 0.2), 2)
			Enemy.Type.BAT:
				# Winged creature with curved bat wings
				var s: float = float(TILE_SIZE) * 0.35
				# Body (oval)
				draw_circle(Vector2(ecx, ecy), s * 0.4, ecolor)
				# Curved wings
				var wing_pts_left: PackedVector2Array = PackedVector2Array([
					Vector2(ecx - s * 0.2, ecy),
					Vector2(ecx - s * 0.8, ecy - s * 0.6),
					Vector2(ecx - s * 0.4, ecy - s * 0.2),
					Vector2(ecx - s * 0.6, ecy + s * 0.4)
				])
				var wing_pts_right: PackedVector2Array = PackedVector2Array([
					Vector2(ecx + s * 0.2, ecy),
					Vector2(ecx + s * 0.8, ecy - s * 0.6),
					Vector2(ecx + s * 0.4, ecy - s * 0.2),
					Vector2(ecx + s * 0.6, ecy + s * 0.4)
				])
				draw_colored_polygon(wing_pts_left, ecolor)
				draw_colored_polygon(wing_pts_right, ecolor)
			# Eyes
				draw_circle(Vector2(ecx - s * 0.15, ecy - s * 0.1), s * 0.08, Color(0.1, 0.1, 0.1))
				draw_circle(Vector2(ecx + s * 0.15, ecy - s * 0.1), s * 0.08, Color(0.1, 0.1, 0.1))
			Enemy.Type.SKELETON:
				# Detailed skull with nasal cavity and teeth
				var s: float = float(TILE_SIZE) * 0.32
				draw_circle(Vector2(ecx, ecy - s * 0.2), s * 0.8, ecolor)
				# Jaw with teeth
				draw_rect(Rect2(ecx - s * 0.5, ecy + s * 0.2, s * 1.0, s * 0.6), ecolor)
				# Teeth
				for i in range(4):
					var tooth_x = ecx - s * 0.4 + i * s * 0.25
					draw_rect(Rect2(tooth_x - s * 0.05, ecy + s * 0.2, s * 0.1, s * 0.2), Color(0.9, 0.9, 0.9))
				# Eye sockets
				draw_circle(Vector2(ecx - s * 0.3, ecy - s * 0.3), s * 0.2, Color(0.1, 0.1, 0.1))
				draw_circle(Vector2(ecx + s * 0.3, ecy - s * 0.3), s * 0.2, Color(0.1, 0.1, 0.1))
				# Nasal cavity
				draw_circle(Vector2(ecx, ecy - s * 0.1), s * 0.15, Color(0.1, 0.1, 0.1))
			Enemy.Type.ORC:
				# Brutish square with tusks
				var s: float = float(TILE_SIZE) * 0.38
				draw_rect(Rect2(ecx - s, ecy - s, s * 2.0, s * 2.0), ecolor)
				# Tusks (triangles)
				draw_colored_polygon(PackedVector2Array([
					Vector2(ecx - s * 0.6, ecy + s * 0.5),
					Vector2(ecx - s * 0.3, ecy + s * 1.1),
					Vector2(ecx - s * 0.1, ecy + s * 0.5)
				]), Color(0.9, 0.9, 0.8))
				draw_colored_polygon(PackedVector2Array([
					Vector2(ecx + s * 0.6, ecy + s * 0.5),
					Vector2(ecx + s * 0.3, ecy + s * 1.1),
					Vector2(ecx + s * 0.1, ecy + s * 0.5)
				]), Color(0.9, 0.9, 0.8))
			Enemy.Type.WRAITH:
				# Ghostly wavy shape
				var s: float = float(TILE_SIZE) * 0.4
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s),
					Vector2(ecx + s * 0.7, ecy - s * 0.3),
					Vector2(ecx + s * 0.5, ecy + s * 0.3),
					Vector2(ecx + s * 0.8, ecy + s),
					Vector2(ecx, ecy + s * 0.6),
					Vector2(ecx - s * 0.8, ecy + s),
					Vector2(ecx - s * 0.5, ecy + s * 0.3),
					Vector2(ecx - s * 0.7, ecy - s * 0.3)
				])
				draw_colored_polygon(pts, ecolor)
			Enemy.Type.FIRE_IMP:
				# Flame shape with horns
				var s: float = float(TILE_SIZE) * 0.35
				# Body flame
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s),
					Vector2(ecx + s * 0.8, ecy + s * 0.8),
					Vector2(ecx, ecy + s * 0.4),
					Vector2(ecx - s * 0.8, ecy + s * 0.8)
				])
				draw_colored_polygon(pts, ecolor)
				# Inner flame
				draw_colored_polygon(PackedVector2Array([
					Vector2(ecx, ecy - s * 0.5),
					Vector2(ecx + s * 0.4, ecy + s * 0.4),
					Vector2(ecx - s * 0.4, ecy + s * 0.4)
				]), Color(1.0, 0.9, 0.3))
			Enemy.Type.GOLEM:
				# Thick square with cracks
				var s: float = float(TILE_SIZE) * 0.4
				draw_rect(Rect2(ecx - s, ecy - s, s * 2.0, s * 2.0), ecolor)
				# Crack pattern
				var cs: float = s * 0.15
				draw_line(Vector2(ecx - s * 0.5, ecy - s * 0.8), Vector2(ecx, ecy), Color(0.25, 0.25, 0.27), cs)
				draw_line(Vector2(ecx, ecy), Vector2(ecx + s * 0.6, ecy + s * 0.7), Color(0.25, 0.25, 0.27), cs)
			Enemy.Type.GHOST:
				# Translucent wavy ghost
				var s: float = float(TILE_SIZE) * 0.38
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s),
					Vector2(ecx + s * 0.8, ecy - s * 0.2),
					Vector2(ecx + s * 0.6, ecy + s),
					Vector2(ecx + s * 0.2, ecy + s * 0.6),
					Vector2(ecx - s * 0.2, ecy + s),
					Vector2(ecx - s * 0.6, ecy + s * 0.6),
					Vector2(ecx - s * 0.8, ecy - s * 0.2)
				])
				draw_colored_polygon(pts, ecolor)
			Enemy.Type.SPIDER:
				# Spider body with legs - oval body
				var s: float = float(TILE_SIZE) * 0.25
				# Oval body
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s * 0.7),
					Vector2(ecx + s * 0.8, ecy),
					Vector2(ecx, ecy + s * 0.7),
					Vector2(ecx - s * 0.8, ecy)
				])
				draw_colored_polygon(pts, ecolor)
				# Legs
				for i in range(4):
					var angle: float = PI * 0.2 + i * PI * 0.2
					draw_line(Vector2(ecx, ecy), Vector2(ecx + cos(angle) * s * 1.8, ecy + sin(angle) * s * 1.8), ecolor, 2)
					draw_line(Vector2(ecx, ecy), Vector2(ecx - cos(angle) * s * 1.8, ecy + sin(angle) * s * 1.8), ecolor, 2)
			Enemy.Type.MIMIC:
				if enemy.mimic_revealed:
					# Monster form - jagged mouth
					var s: float = float(TILE_SIZE) * 0.38
					draw_rect(Rect2(ecx - s, ecy - s * 0.6, s * 2.0, s * 1.4), ecolor)
					# Teeth
					for i in range(4):
						draw_colored_polygon(PackedVector2Array([
							Vector2(ecx - s + i * s * 0.5, ecy + s * 0.1),
							Vector2(ecx - s * 0.75 + i * s * 0.5, ecy + s * 0.5),
							Vector2(ecx - s * 0.5 + i * s * 0.5, ecy + s * 0.1)
						]), Color(0.9, 0.9, 0.8))
				else:
					# Disguised as gold
					draw_circle(Vector2(ecx, ecy), float(TILE_SIZE) * 0.3, Color(1.0, 0.85, 0.1))
					draw_string(ThemeDB.fallback_font, Vector2(ecx - 5, ecy + 4), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.6, 0.0))
			Enemy.Type.VAMPIRE:
				# Elegant diamond with cape
				var s: float = float(TILE_SIZE) * 0.4
				# Cape (wider triangle)
				draw_colored_polygon(PackedVector2Array([
					Vector2(ecx, ecy - s * 0.5),
					Vector2(ecx + s, ecy + s),
					Vector2(ecx - s, ecy + s)
				]), Color(0.2, 0.0, 0.1))
				# Body (diamond)
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s),
					Vector2(ecx + s * 0.5, ecy),
					Vector2(ecx, ecy + s * 0.5),
					Vector2(ecx - s * 0.5, ecy)
				])
				draw_colored_polygon(pts, ecolor)
			Enemy.Type.TROLL:
				# Large lumpy shape
				var s: float = float(TILE_SIZE) * 0.42
				# Body - irregular blob
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s),
					Vector2(ecx + s * 0.8, ecy - s * 0.5),
					Vector2(ecx + s * 0.9, ecy + s * 0.3),
					Vector2(ecx + s * 0.5, ecy + s * 0.8),
					Vector2(ecx, ecy + s),
					Vector2(ecx - s * 0.5, ecy + s * 0.8),
					Vector2(ecx - s * 0.9, ecy + s * 0.3),
					Vector2(ecx - s * 0.8, ecy - s * 0.5)
				])
				draw_colored_polygon(pts, ecolor)
			Enemy.Type.CRYSTAL_GOLEM:
				# Crystal shape (hexagon)
				var s: float = float(TILE_SIZE) * 0.4
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s),
					Vector2(ecx + s * 0.7, ecy - s * 0.5),
					Vector2(ecx + s * 0.7, ecy + s * 0.5),
					Vector2(ecx, ecy + s),
					Vector2(ecx - s * 0.7, ecy + s * 0.5),
					Vector2(ecx - s * 0.7, ecy - s * 0.5)
				])
				draw_colored_polygon(pts, ecolor)
				# Inner shine
				draw_circle(Vector2(ecx - s * 0.2, ecy - s * 0.2), s * 0.2, Color(1.0, 1.0, 1.0, 0.4))
				draw_colored_polygon(pts, ecolor)
			Enemy.Type.WISP:
				# Glowing orb with trailing particles
				var s: float = float(TILE_SIZE) * 0.3
				# Outer glow
				draw_circle(Vector2(ecx, ecy), s * 1.3, Color(1.0, 1.0, 0.6, 0.2))
				# Main body
				draw_circle(Vector2(ecx, ecy), s, ecolor)
				# Inner bright core
				draw_circle(Vector2(ecx, ecy), s * 0.5, Color(1.0, 1.0, 0.9))
				# Trailing particles
				draw_circle(Vector2(ecx + s * 0.6, ecy + s * 0.7), s * 0.2, Color(0.9, 0.95, 0.4, 0.4))
			Enemy.Type.RAZOR_BEAST:
				# Spiky quadruped with sharp edges
				var s: float = float(TILE_SIZE) * 0.38
				# Body - angular shape
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s * 0.8),
					Vector2(ecx + s * 0.6, ecy - s * 0.4),
					Vector2(ecx + s * 0.9, ecy + s * 0.2),
					Vector2(ecx + s * 0.5, ecy + s * 0.7),
					Vector2(ecx, ecy + s * 0.5),
					Vector2(ecx - s * 0.5, ecy + s * 0.7),
					Vector2(ecx - s * 0.9, ecy + s * 0.2),
					Vector2(ecx - s * 0.6, ecy - s * 0.4)
				])
				draw_colored_polygon(pts, ecolor)
				# Spikes
				draw_colored_polygon(PackedVector2Array([
					Vector2(ecx - s * 0.3, ecy - s * 0.6),
					Vector2(ecx, ecy - s * 1.1),
					Vector2(ecx + s * 0.3, ecy - s * 0.6)
				]), Color(0.9, 0.9, 0.9))
				draw_colored_polygon(PackedVector2Array([
					Vector2(ecx + s * 0.5, ecy - s * 0.2),
					Vector2(ecx + s * 1.0, ecy - s * 0.4),
					Vector2(ecx + s * 0.6, ecy + s * 0.1)
				]), Color(0.9, 0.9, 0.9))
			Enemy.Type.NECROMANCER:
				# Hooded figure with glowing hands
				var s: float = float(TILE_SIZE) * 0.35
				# Robe body
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s * 0.9),
					Vector2(ecx + s * 0.5, ecy - s * 0.3),
					Vector2(ecx + s * 0.7, ecy + s * 0.8),
					Vector2(ecx - s * 0.7, ecy + s * 0.8),
					Vector2(ecx - s * 0.5, ecy - s * 0.3)
				])
				draw_colored_polygon(pts, ecolor)
				# Hood shadow
				draw_circle(Vector2(ecx, ecy - s * 0.5), s * 0.35, Color(0.1, 0.05, 0.15))
				# Glowing eyes
				draw_circle(Vector2(ecx - s * 0.12, ecy - s * 0.55), s * 0.08, Color(0.8, 0.2, 1.0))
				draw_circle(Vector2(ecx + s * 0.12, ecy - s * 0.55), s * 0.08, Color(0.8, 0.2, 1.0))
				# Glowing hands (magic)
				draw_circle(Vector2(ecx - s * 0.6, ecy + s * 0.1), s * 0.15, Color(0.6, 0.1, 0.8, 0.7))
				draw_circle(Vector2(ecx + s * 0.6, ecy + s * 0.1), s * 0.15, Color(0.6, 0.1, 0.8, 0.7))
			Enemy.Type.DJINN:
				# Smokeless fire spirit - wavy ethereal form
				var s: float = float(TILE_SIZE) * 0.38
				# Main body - flame-like wavy shape
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s * 1.1),
					Vector2(ecx + s * 0.6, ecy - s * 0.5),
					Vector2(ecx + s * 0.8, ecy + s * 0.2),
					Vector2(ecx + s * 0.4, ecy + s * 0.7),
					Vector2(ecx, ecy + s * 0.5),
					Vector2(ecx - s * 0.4, ecy + s * 0.7),
					Vector2(ecx - s * 0.8, ecy + s * 0.2),
					Vector2(ecx - s * 0.6, ecy - s * 0.5)
				])
				draw_colored_polygon(pts, ecolor)
				# Inner fire glow
				draw_circle(Vector2(ecx, ecy - s * 0.3), s * 0.25, Color(0.4, 0.2, 0.8, 0.6))
				# Eyes - malevolent glow
				draw_circle(Vector2(ecx - s * 0.2, ecy - s * 0.5), s * 0.1, Color(1.0, 0.3, 0.1))
				draw_circle(Vector2(ecx + s * 0.2, ecy - s * 0.5), s * 0.1, Color(1.0, 0.3, 0.1))
			Enemy.Type.BOSS_SLIME:
				# Large blob with inner core
				var s: float = float(TILE_SIZE) * 0.48
				# Outer blob shape
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s),
					Vector2(ecx + s * 0.9, ecy - s * 0.4),
					Vector2(ecx + s * 0.85, ecy + s * 0.5),
					Vector2(ecx + s * 0.4, ecy + s * 0.85),
					Vector2(ecx, ecy + s),
					Vector2(ecx - s * 0.4, ecy + s * 0.85),
					Vector2(ecx - s * 0.85, ecy + s * 0.5),
					Vector2(ecx - s * 0.9, ecy - s * 0.4)
				])
				draw_colored_polygon(pts, ecolor)
				# Inner core
				var inner_pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s * 0.5),
					Vector2(ecx + s * 0.4, ecy),
					Vector2(ecx, ecy + s * 0.5),
					Vector2(ecx - s * 0.4, ecy)
				])
				draw_colored_polygon(inner_pts, Color(0.2, 0.6, 0.05))
			Enemy.Type.BOSS_LICH:
				# Purple skull with crown
				var s: float = float(TILE_SIZE) * 0.45
				# Skull - oval shape
				var skull_pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s * 0.8),
					Vector2(ecx + s * 0.7, ecy - s * 0.3),
					Vector2(ecx + s * 0.6, ecy + s * 0.4),
					Vector2(ecx + s * 0.4, ecy + s * 0.7),
					Vector2(ecx - s * 0.4, ecy + s * 0.7),
					Vector2(ecx - s * 0.6, ecy + s * 0.4),
					Vector2(ecx - s * 0.7, ecy - s * 0.3)
				])
				draw_colored_polygon(skull_pts, ecolor)
				# Jaw
				draw_rect(Rect2(ecx - s * 0.4, ecy + s * 0.3, s * 0.8, s * 0.5), ecolor)
				# Crown spikes
				for i in range(3):
					draw_colored_polygon(PackedVector2Array([
						Vector2(ecx - s * 0.5 + i * s * 0.5, ecy - s * 0.6),
						Vector2(ecx - s * 0.35 + i * s * 0.5, ecy - s),
						Vector2(ecx - s * 0.2 + i * s * 0.5, ecy - s * 0.6)
					]), Color(1.0, 0.8, 0.0))
				# Glowing eyes
				draw_circle(Vector2(ecx - s * 0.25, ecy - s * 0.2), s * 0.15, Color(0.9, 0.3, 1.0))
				draw_circle(Vector2(ecx + s * 0.25, ecy - s * 0.2), s * 0.15, Color(0.9, 0.3, 1.0))
			Enemy.Type.BOSS_DRAGON:
				# Large hexagon with horns
				var s: float = float(TILE_SIZE) * 0.48
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s),
					Vector2(ecx + s * 0.85, ecy - s * 0.4),
					Vector2(ecx + s * 0.85, ecy + s * 0.4),
					Vector2(ecx, ecy + s),
					Vector2(ecx - s * 0.85, ecy + s * 0.4),
					Vector2(ecx - s * 0.85, ecy - s * 0.4)
				])
				draw_colored_polygon(pts, ecolor)
				# Horns
				draw_colored_polygon(PackedVector2Array([
					Vector2(ecx - s * 0.6, ecy - s * 0.8),
					Vector2(ecx - s * 0.9, ecy - s * 1.2),
					Vector2(ecx - s * 0.3, ecy - s * 0.9)
				]), Color(0.5, 0.1, 0.1))
				draw_colored_polygon(PackedVector2Array([
					Vector2(ecx + s * 0.6, ecy - s * 0.8),
					Vector2(ecx + s * 0.9, ecy - s * 1.2),
					Vector2(ecx + s * 0.3, ecy - s * 0.9)
				]), Color(0.5, 0.1, 0.1))
				# Glowing eye
				draw_circle(Vector2(ecx, ecy), float(TILE_SIZE) * 0.12, Color(1.0, 0.3, 0.0))

		# Enemy HP bar (small bar above enemy)
		if enemy.hp < enemy.max_hp:
			var bar_w: float = float(TILE_SIZE - 4)
			# Boss gets wider bar
			if enemy.is_boss:
				bar_w = float(TILE_SIZE) * 1.2
			var bar_h: float = 3.0
			if enemy.is_boss:
				bar_h = 5.0
			var bar_x: float = ex + 2.0
			if enemy.is_boss:
				bar_x = ecx - bar_w / 2.0
			var bar_y: float = ey - 5.0
			if enemy.is_boss:
				bar_y = ey - 8.0
			var hp_ratio: float = float(enemy.hp) / float(enemy.max_hp)
			draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.3, 0.0, 0.0))
			draw_rect(Rect2(bar_x, bar_y, bar_w * hp_ratio, bar_h), Color(0.9, 0.1, 0.1))
			if enemy.is_boss:
				# Boss name above HP bar
				draw_string(ThemeDB.fallback_font, Vector2(bar_x, bar_y - 2.0), enemy.name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.3, 0.3))
	
	# Draw traps (only if visible and triggered)
	for trap in traps:
		if not trap.visible:
			continue
		if not _is_visible(trap.pos):
			continue
		var tx: float = float(trap.pos.x * TILE_SIZE) + camera_offset.x
		var ty: float = float(trap.pos.y * TILE_SIZE) + camera_offset.y
		var tcx: float = tx + float(TILE_SIZE) / 2.0
		var tcy: float = ty + float(TILE_SIZE) / 2.0
		var tcolor: Color = trap.get_color()
		var ts: float = float(TILE_SIZE) * 0.3
		
		match trap.type:
			Trap.Type.SPIKES:
				# Triangle spikes
				for i in range(3):
					var offset_x: float = (i - 1) * ts * 0.6
					var pts: PackedVector2Array = PackedVector2Array([
						Vector2(tcx + offset_x, tcy - ts * 0.5),
						Vector2(tcx + offset_x - ts * 0.25, tcy + ts * 0.3),
						Vector2(tcx + offset_x + ts * 0.25, tcy + ts * 0.3)
					])
					draw_colored_polygon(pts, tcolor)
			Trap.Type.POISON_DART:
				# Dart shape
				draw_circle(Vector2(tcx, tcy), ts * 0.3, tcolor)
				draw_rect(Rect2(tcx - ts * 0.1, tcy - ts * 0.5, ts * 0.2, ts * 0.5), tcolor)
			Trap.Type.FIRE_VENT:
				# Fire glow
				draw_circle(Vector2(tcx, tcy), ts * 0.6, Color(1.0, 0.5, 0.1, 0.5))
				draw_circle(Vector2(tcx, tcy), ts * 0.3, tcolor)
			Trap.Type.TELEPORT:
				# Swirl pattern
				draw_circle(Vector2(tcx, tcy), ts * 0.5, tcolor)
				draw_circle(Vector2(tcx, tcy), ts * 0.25, Color(0.3, 0.1, 0.5))
			Trap.Type.ICE_PATCH:
				# Ice crystals
				draw_rect(Rect2(tcx - ts * 0.5, tcy - ts * 0.1, ts, ts * 0.2), tcolor)
				draw_rect(Rect2(tcx - ts * 0.1, tcy - ts * 0.5, ts * 0.2, ts), tcolor)
			Trap.Type.LAVA_CRACK:
				# Crack in ground with glow
				draw_circle(Vector2(tcx, tcy), ts * 0.4, Color(1.0, 0.3, 0.0, 0.7))
				draw_rect(Rect2(tcx - ts * 0.3, tcy - ts * 0.05, ts * 0.6, ts * 0.1), tcolor)
			Trap.Type.SHADOW_PIT:
				# Dark pit
				draw_circle(Vector2(tcx, tcy), ts * 0.5, Color(0.0, 0.0, 0.0, 0.8))
				draw_circle(Vector2(tcx, tcy), ts * 0.3, tcolor)
			Trap.Type.SPIRIT_WISP:
				# Ghostly wisp
				draw_circle(Vector2(tcx, tcy - ts * 0.2), ts * 0.3, tcolor)
				draw_rect(Rect2(tcx - ts * 0.2, tcy, ts * 0.4, ts * 0.3), Color(tcolor.r, tcolor.g, tcolor.b, 0.5))
	
	# Draw player (knight-like shape)
	var player_color: Color = color_player
	if damage_flash_timer > 0:
		player_color = Color(1.0, 0.2, 0.2)
	if levelup_flash_timer > 0:
		# Gold flash on level up
		var flash_t: float = levelup_flash_timer / 1.5
		player_color = Color(1.0, 0.85, 0.1).lerp(color_player, 1.0 - flash_t)
	var player_screen: Vector2 = Vector2(
		float(player_pos.x * TILE_SIZE) + camera_offset.x + float(TILE_SIZE) / 2.0,
		float(player_pos.y * TILE_SIZE) + camera_offset.y + float(TILE_SIZE) / 2.0
	)
	var ps: float = float(TILE_SIZE) * 0.38
	# Body (shield shape - pointed bottom)
	var body_pts: PackedVector2Array = PackedVector2Array([
		Vector2(player_screen.x, player_screen.y - ps),
		Vector2(player_screen.x + ps * 0.8, player_screen.y - ps * 0.3),
		Vector2(player_screen.x + ps * 0.7, player_screen.y + ps * 0.5),
		Vector2(player_screen.x, player_screen.y + ps),
		Vector2(player_screen.x - ps * 0.7, player_screen.y + ps * 0.5),
		Vector2(player_screen.x - ps * 0.8, player_screen.y - ps * 0.3)
	])
	draw_colored_polygon(body_pts, player_color)
	# Helmet visor line
	draw_line(Vector2(player_screen.x - ps * 0.4, player_screen.y - ps * 0.3),
		Vector2(player_screen.x + ps * 0.4, player_screen.y - ps * 0.3),
		Color(0.1, 0.1, 0.1), 2.0)
	# Highlight
	draw_circle(Vector2(player_screen.x - ps * 0.3, player_screen.y - ps * 0.5), ps * 0.15, Color(0.9, 1.0, 0.9, 0.4))
	# Sword (right side)
	var sword_color: Color = Color(0.7, 0.7, 0.75)
	draw_line(Vector2(player_screen.x + ps * 0.9, player_screen.y - ps * 0.2),
		Vector2(player_screen.x + ps * 1.4, player_screen.y - ps * 0.8),
		sword_color, 3.0)
	# Sword handle
	draw_line(Vector2(player_screen.x + ps * 0.85, player_screen.y - ps * 0.1),
		Vector2(player_screen.x + ps * 1.0, player_screen.y - ps * 0.3),
		Color(0.5, 0.3, 0.1), 2.0)
	# Shield (left side)
	var shield_pts: PackedVector2Array = PackedVector2Array([
		Vector2(player_screen.x - ps * 0.9, player_screen.y - ps * 0.3),
		Vector2(player_screen.x - ps * 1.1, player_screen.y),
		Vector2(player_screen.x - ps * 0.9, player_screen.y + ps * 0.3),
		Vector2(player_screen.x - ps * 0.7, player_screen.y)
	])
	draw_colored_polygon(shield_pts, Color(0.6, 0.5, 0.3))

	# Draw floating damage numbers
	for ft in floating_texts:
		var alpha: float = 1.0 - (ft.age / 1.0)  # Fade out over 1 second
		var ft_color: Color = Color(ft.color.r, ft.color.g, ft.color.b, alpha)
		var font_size: int = 16 if ft.text.begins_with("-") else 14
		draw_string(ThemeDB.fallback_font, ft.pos - Vector2(10, 0), ft.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ft_color)

	# === HUD ===

	# === HUD ===
	var hud_h: float = 76.0
	draw_rect(Rect2(0, 0, viewport_w, hud_h), color_hud_bg)

	# HUD line 1: Floor | Level | Score
	var floor_label: String = "Floor " + str(current_floor)
	if is_boss_floor and not boss_defeated:
		floor_label += " [BOSS]"
	var hud_text: String = floor_label + "  |  Lv." + str(player_level) + "  |  Score:" + str(score)
	draw_string(ThemeDB.fallback_font, Vector2(10, 18), hud_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color_text)

	# HP bar
	var hp_label: String = "HP:" + str(player_hp) + "/" + str(player_max_hp)
	draw_string(ThemeDB.fallback_font, Vector2(10, 36), hp_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color_text)

	var bar_start_x: float = 100.0
	var bar_w: float = float(viewport_w) - bar_start_x - 10.0
	var bar_h: float = 12.0
	var bar_y: float = 26.0
	var hp_ratio: float = float(player_hp) / float(player_max_hp)
	draw_rect(Rect2(bar_start_x, bar_y, bar_w, bar_h), Color(0.3, 0.0, 0.0))
	var hp_color: Color
	if hp_ratio > 0.5:
		hp_color = Color(0.2, 0.8, 0.2)
	elif hp_ratio > 0.25:
		hp_color = Color(0.9, 0.7, 0.1)
	else:
		hp_color = Color(0.9, 0.1, 0.1)
	draw_rect(Rect2(bar_start_x, bar_y, bar_w * hp_ratio, bar_h), hp_color)

	# XP bar
	var xp_needed: int = _get_xp_for_next_level()
	var xp_label: String = "XP:" + str(player_xp) + "/" + str(xp_needed)
	draw_string(ThemeDB.fallback_font, Vector2(10, 52), xp_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.8, 1.0))

	var xp_bar_y: float = 42.0
	var xp_ratio: float = float(player_xp) / float(maxi(xp_needed, 1))
	xp_ratio = clampf(xp_ratio, 0.0, 1.0)
	draw_rect(Rect2(bar_start_x, xp_bar_y, bar_w, 10.0), Color(0.1, 0.1, 0.2))
	draw_rect(Rect2(bar_start_x, xp_bar_y, bar_w * xp_ratio, 10.0), Color(0.3, 0.5, 1.0))



	# === MESSAGE LOG ===
	_draw_message_log(hud_h)

	# === MINIMAP ===
	_draw_minimap()

	# Level up flash text
	if levelup_flash_timer > 0:
		var lu_alpha: float = clampf(levelup_flash_timer / 1.5, 0.0, 1.0)
		var lu_text: String = "LEVEL UP!"
		var lu_y: float = float(viewport_h) / 2.0 - 40.0
		var lu_color: Color = Color(1.0, 0.85, 0.1, lu_alpha)
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 60.0, lu_y), lu_text, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 26, lu_color)

	# === D-PAD ===
	_draw_dpad()

	# Boss floor warning
	if is_boss_floor and not boss_defeated:
		var warn_alpha: float = 0.5 + 0.3 * sin(float(turn_count) * 0.5)
		var warn_color: Color = Color(1.0, 0.2, 0.1, clampf(warn_alpha, 0.3, 0.8))
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 55.0, viewport_h - 20.0), "BOSS FLOOR", HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 18, warn_color)

	# Game over overlay
	if game_over:
		draw_rect(Rect2(0, 0, viewport_w, viewport_h), Color(0.0, 0.0, 0.0, 0.75))

		var title: String = "YOU DIED"
		var title_w: float = float(title.length()) * 14.0
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - title_w / 2.0, float(viewport_h) / 2.0 - 80.0), title, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 28, Color(0.9, 0.15, 0.15))

		var score_text: String = "Score: " + str(score)
		var floor_text: String = "Reached Floor " + str(current_floor)
		var kills_text: String = "Enemies Slain: " + str(kill_count)
		var level_text: String = "Level: " + str(player_level)
		var gold_text2: String = "Gold: " + str(gold_collected)
		var restart_text: String = "Tap or press any key to restart"

		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - float(score_text.length()) * 6.0, float(viewport_h) / 2.0 - 30.0), score_text, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 22, Color(1.0, 0.85, 0.1))
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - float(floor_text.length()) * 5.0, float(viewport_h) / 2.0 + 0.0), floor_text, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 18, color_text)
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - float(level_text.length()) * 5.0, float(viewport_h) / 2.0 + 25.0), level_text, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 18, Color(0.6, 0.8, 1.0))
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - float(kills_text.length()) * 5.0, float(viewport_h) / 2.0 + 50.0), kills_text, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 18, color_text)
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - float(gold_text2.length()) * 5.0, float(viewport_h) / 2.0 + 75.0), gold_text2, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 18, color_text)
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - float(restart_text.length()) * 4.0, float(viewport_h) / 2.0 + 120.0), restart_text, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 14, Color(0.6, 0.6, 0.5))

	# Draw shop button for mobile (right side)
	if _is_shop_floor_num(current_floor) and not has_visited_shop_this_floor and not in_shop:
		shop_btn_rect = Rect2(float(viewport_w) - 80.0, float(viewport_h) - 100.0, 70.0, 70.0)
		var btn_color: Color = Color(0.8, 0.6, 0.1, 0.7)
		draw_rect(shop_btn_rect, btn_color, true, 8.0)
		draw_string(ThemeDB.fallback_font, Vector2(shop_btn_rect.position.x + 12, shop_btn_rect.position.y + 40), "SHOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

	# === INVENTORY UI ===
	if in_inventory:
		# Dark overlay
		draw_rect(Rect2(0, 0, viewport_w, viewport_h), Color(0.0, 0.0, 0.0, 0.8))
		
		# Inventory title
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 60.0, 40.0), "INVENTORY", HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 24, Color(1.0, 0.9, 0.3))
		
		# Equipment slots
		var slot_y: float = 80.0
		var slot_height: float = 60.0
		var slot_width: float = 200.0
		var slot_x: float = float(viewport_w) / 2.0 - slot_width / 2.0
		
		# Weapon slot
		var weapon_color: Color = Color(0.3, 0.3, 0.4) if inventory_selected_slot == 0 else Color(0.2, 0.2, 0.3)
		draw_rect(Rect2(slot_x, slot_y, slot_width, slot_height), weapon_color)
		draw_string(ThemeDB.fallback_font, Vector2(slot_x + 10, slot_y + 15), "WEAPON", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		if equipped_weapon:
			draw_string(ThemeDB.fallback_font, Vector2(slot_x + 10, slot_y + 35), equipped_weapon.name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.8, 0.9))
			draw_string(ThemeDB.fallback_font, Vector2(slot_x + 10, slot_y + 50), equipped_weapon.get_description(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.9, 0.6))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(slot_x + 10, slot_y + 35), "Empty", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.6))
		
		# Armor slot
		slot_y += slot_height + 10
		var armor_color: Color = Color(0.3, 0.3, 0.4) if inventory_selected_slot == 1 else Color(0.2, 0.2, 0.3)
		draw_rect(Rect2(slot_x, slot_y, slot_width, slot_height), armor_color)
		draw_string(ThemeDB.fallback_font, Vector2(slot_x + 10, slot_y + 15), "ARMOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		if equipped_armor:
			draw_string(ThemeDB.fallback_font, Vector2(slot_x + 10, slot_y + 35), equipped_armor.name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.8, 0.9))
			draw_string(ThemeDB.fallback_font, Vector2(slot_x + 10, slot_y + 50), equipped_armor.get_description(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.9, 0.6))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(slot_x + 10, slot_y + 35), "Empty", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.6))
		
		# Accessory slot
		slot_y += slot_height + 10
		var accessory_color: Color = Color(0.3, 0.3, 0.4) if inventory_selected_slot == 2 else Color(0.2, 0.2, 0.3)
		draw_rect(Rect2(slot_x, slot_y, slot_width, slot_height), accessory_color)
		draw_string(ThemeDB.fallback_font, Vector2(slot_x + 10, slot_y + 15), "ACCESSORY", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		if equipped_accessory:
			draw_string(ThemeDB.fallback_font, Vector2(slot_x + 10, slot_y + 35), equipped_accessory.name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.8, 0.9))
			draw_string(ThemeDB.fallback_font, Vector2(slot_x + 10, slot_y + 50), equipped_accessory.get_description(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.9, 0.6))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(slot_x + 10, slot_y + 35), "Empty", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.6))
		
		# Instructions
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, slot_y + slot_height + 20), "Use arrows to select | SPACE to unequip | ESC to close", HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 12, Color(0.7, 0.7, 0.8))

	# === STATS UI ===
	if in_stats:
		# Dark overlay
		draw_rect(Rect2(0, 0, viewport_w, viewport_h), Color(0.0, 0.0, 0.0, 0.8))
		
		# Stats title
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 40.0, 40.0), "STATS", HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 24, Color(0.6, 0.8, 1.0))
		
		# Stats info
		var stat_y: float = 80.0
		var line_height: float = 20.0
		
		# Level and XP
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "Level: " + str(player_level), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		stat_y += line_height
		var xp_req: int = _get_xp_for_next_level()
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "XP: " + str(player_xp) + "/" + str(xp_req), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.8, 1.0))
		stat_y += line_height * 2
		
		# Combat stats
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "HP: " + str(player_hp) + "/" + str(player_max_hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.1, 0.1))
		stat_y += line_height
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "ATK: " + str(player_atk) + " (Base: " + str(base_atk) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.6, 0.1))
		stat_y += line_height
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "DEF: " + str(player_def) + " (Base: " + str(base_def) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.3, 0.7, 0.9))
		stat_y += line_height
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "Crit Chance: " + str(int(crit_chance * 100)) + "%", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.4, 0.9))
		stat_y += line_height * 2
		
		# Equipment summary
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "EQUIPMENT:", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.9, 0.3))
		stat_y += line_height
		if equipped_weapon:
			draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "Weapon: " + equipped_weapon.name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.9))
			stat_y += line_height
		else:
			draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "Weapon: None", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.6))
			stat_y += line_height
			
		if equipped_armor:
			draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "Armor: " + equipped_armor.name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.9))
			stat_y += line_height
		else:
			draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "Armor: None", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.6))
			stat_y += line_height
			
		if equipped_accessory:
			draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "Accessory: " + equipped_accessory.name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.9))
			stat_y += line_height
		else:
			draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y), "Accessory: None", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.6))
			stat_y += line_height
			
		# Instructions
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - 100.0, stat_y + 20), "Press C to close", HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 12, Color(0.7, 0.7, 0.8))
func _draw_message_log(hud_h: float) -> void:
	if message_log.is_empty():
		return
	var log_y: float = hud_h + 4.0
	var line_h: float = 16.0
	var max_display: int = mini(message_log.size(), MAX_LOG_MESSAGES)
	# Draw background for log area
	draw_rect(Rect2(0, log_y, viewport_w, line_h * float(max_display) + 4.0), Color(0.0, 0.0, 0.0, 0.5))
	for i in range(max_display):
		var entry: Dictionary = message_log[i]
		var age: float = entry["age"]
		var text: String = entry["text"]
		# Fade from white to gray based on age and position
		var alpha: float = clampf(1.0 - (age / 8.0) - float(i) * 0.15, 0.2, 1.0)
		var msg_color: Color = Color(0.9, 0.9, 0.8, alpha)
		# Level up messages in gold
		if text.begins_with("LEVEL UP"):
			msg_color = Color(1.0, 0.85, 0.1, alpha)
		elif text.begins_with("==="):
			msg_color = Color(1.0, 0.3, 0.2, alpha)
		elif text.begins_with("+"):
			msg_color = Color(0.5, 0.8, 1.0, alpha)
		var ty: float = log_y + 14.0 + float(i) * line_h
		draw_string(ThemeDB.fallback_font, Vector2(8, ty), text, HORIZONTAL_ALIGNMENT_LEFT, viewport_w - 16, 12, msg_color)

func _draw_minimap() -> void:
	var mm_x: float = float(viewport_w - MINIMAP_SIZE - MINIMAP_MARGIN)
	var mm_y: float = 80.0  # Below expanded HUD

	draw_rect(Rect2(mm_x - 2, mm_y - 2, MINIMAP_SIZE + 4, MINIMAP_SIZE + 4), Color(0.3, 0.3, 0.3, 0.8))
	draw_rect(Rect2(mm_x, mm_y, MINIMAP_SIZE, MINIMAP_SIZE), Color(0.0, 0.0, 0.0, 0.9))

	minimap_scale = float(MINIMAP_SIZE) / float(maxi(map_data.width, map_data.height))

	for tpos in explored:
		var tx: int = tpos.x
		var ty: int = tpos.y
		var tile: int = map_data.get_tile(tx, ty)
		var px: float = mm_x + float(tx) * minimap_scale
		var py: float = mm_y + float(ty) * minimap_scale
		var ps: float = maxf(minimap_scale, 1.0)

		if tile == TileMapData.Tile.WALL:
			draw_rect(Rect2(px, py, ps, ps), Color(0.2, 0.12, 0.06, 0.7))
		elif tile == TileMapData.Tile.FLOOR or tile == TileMapData.Tile.DOOR:
			draw_rect(Rect2(px, py, ps, ps), Color(0.3, 0.3, 0.35, 0.7))
		elif tile == TileMapData.Tile.STAIRS_DOWN:
			if stairs_found.has(tpos):
				draw_rect(Rect2(px, py, ps + 1.0, ps + 1.0), Color(0.0, 0.9, 0.9))
		elif tile == TileMapData.Tile.SHOP:
			draw_rect(Rect2(px, py, ps + 1.0, ps + 1.0), Color(0.8, 0.7, 0.2))  # Gold/yellow for shop

	# Enemy dots on minimap (visible ones, bosses always if on boss floor)
	for enemy in enemies:
		if not enemy.alive:
			continue
		if _is_visible(enemy.pos) or (is_boss_floor and enemy.is_boss):
			var epx: float = mm_x + float(enemy.pos.x) * minimap_scale
			var epy: float = mm_y + float(enemy.pos.y) * minimap_scale
			var ecolor: Color = Color(1.0, 0.2, 0.2)
			if enemy.is_boss:
				ecolor = Color(1.0, 0.0, 0.5)
			var edot: float = maxf(minimap_scale * 1.2, 2.0)
			if enemy.is_boss:
				edot = maxf(minimap_scale * 2.0, 3.5)
			draw_rect(Rect2(epx - edot * 0.25, epy - edot * 0.25, edot, edot), ecolor)

	# Player dot
	var pp_x: float = mm_x + float(player_pos.x) * minimap_scale
	var pp_y: float = mm_y + float(player_pos.y) * minimap_scale
	var dot_size: float = maxf(minimap_scale * 1.5, 2.5)
	draw_rect(Rect2(pp_x - dot_size * 0.25, pp_y - dot_size * 0.25, dot_size, dot_size), Color(0.2, 1.0, 0.2))


func _draw_dpad() -> void:
	if game_over:
		return
	var rects: Dictionary = _get_dpad_rects()
	var dirs: Dictionary = {
		"up": Vector2i(0, -1),
		"down": Vector2i(0, 1),
		"left": Vector2i(-1, 0),
		"right": Vector2i(1, 0),
	}
	for key in rects:
		var r: Rect2 = rects[key]
		var is_pressed: bool = (dirs[key] == dpad_pressed_dir and dpad_pressed_dir != Vector2i.ZERO)
		var alpha: float = DPAD_PRESSED_ALPHA if is_pressed else DPAD_ALPHA
		# Button background
		draw_rect(r, Color(0.3, 0.3, 0.35, alpha))
		# Button border
		var border_color: Color = Color(0.6, 0.6, 0.65, alpha)
		if is_pressed:
			border_color = Color(0.4, 0.9, 0.4, 0.8)
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2), border_color)
		draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 2, r.size.x, 2), border_color)
		draw_rect(Rect2(r.position.x, r.position.y, 2, r.size.y), border_color)
		draw_rect(Rect2(r.position.x + r.size.x - 2, r.position.y, 2, r.size.y), border_color)
		# Arrow icon
		var cx: float = r.position.x + r.size.x / 2.0
		var cy: float = r.position.y + r.size.y / 2.0
		var arrow_s: float = 12.0
		var arrow_color: Color = Color(0.9, 0.9, 0.9, alpha + 0.2)
		if is_pressed:
			arrow_color = Color(0.4, 1.0, 0.4, 0.9)
		match key:
			"up":
				draw_colored_polygon(PackedVector2Array([
					Vector2(cx, cy - arrow_s),
					Vector2(cx + arrow_s * 0.7, cy + arrow_s * 0.4),
					Vector2(cx - arrow_s * 0.7, cy + arrow_s * 0.4)
				]), arrow_color)
			"down":
				draw_colored_polygon(PackedVector2Array([
					Vector2(cx, cy + arrow_s),
					Vector2(cx + arrow_s * 0.7, cy - arrow_s * 0.4),
					Vector2(cx - arrow_s * 0.7, cy - arrow_s * 0.4)
				]), arrow_color)
			"left":
				draw_colored_polygon(PackedVector2Array([
					Vector2(cx - arrow_s, cy),
					Vector2(cx + arrow_s * 0.4, cy - arrow_s * 0.7),
					Vector2(cx + arrow_s * 0.4, cy + arrow_s * 0.7)
				]), arrow_color)
			"right":
				draw_colored_polygon(PackedVector2Array([
					Vector2(cx + arrow_s, cy),
					Vector2(cx - arrow_s * 0.4, cy - arrow_s * 0.7),
					Vector2(cx - arrow_s * 0.4, cy + arrow_s * 0.7)
				]), arrow_color)

func _try_move(dir: Vector2i) -> void:
	# Process status effects at start of turn
	_process_status_effects()
	
	var new_pos: Vector2i = player_pos + dir

	if not map_data.is_walkable(new_pos.x, new_pos.y):
		return

	# Check if enemy is at new_pos (bump attack)
	var target_enemy: Enemy = _get_enemy_at(new_pos)
	if target_enemy != null:
		_player_attack(target_enemy)
		turn_count += 1
		_enemy_turn()
		_update_visibility()
		_update_camera()
		queue_redraw()
		return

	# Move player to new position
	player_pos = new_pos
	
	# Check for item pickup
	_check_item_pickup()
	
	# Check traps at new position
	_check_traps()

	# Check stairs
	var tile: int = map_data.get_tile(player_pos.x, player_pos.y)
	if tile == TileMapData.Tile.STAIRS_DOWN:
		current_floor += 1
		_generate_floor()
		return

	# Enemy turn after player moves
	turn_count += 1
	_enemy_turn()
	_update_visibility()
	_update_camera()
	queue_redraw()
func _check_item_pickup() -> void:
	for item in items:
		if item.collected:
			continue
		if item.pos == player_pos:
			item.collected = true
			match item.type:
				Item.Type.HEALTH_POTION:
					var heal: int = mini(8, player_max_hp - player_hp)
					player_hp += heal
					_spawn_floating_text(player_pos, "+" + str(heal) + " HP", Color(0.2, 1.0, 0.3))
					_add_log_message("Picked up Health Potion! +" + str(heal) + " HP")
				Item.Type.STRENGTH_POTION:
					base_atk += 1
					_spawn_floating_text(player_pos, "+1 ATK", Color(1.0, 0.6, 0.2))
					_add_log_message("Picked up Strength Potion! +1 ATK")
					_recalculate_stats()
				Item.Type.SHIELD_SCROLL:
					base_def += 1
					_spawn_floating_text(player_pos, "+1 DEF", Color(0.3, 0.6, 1.0))
					_add_log_message("Picked up Shield Scroll! +1 DEF")
					_recalculate_stats()
				Item.Type.GOLD:
					gold_collected += 10
					_spawn_floating_text(player_pos, "+10g", Color(1.0, 0.85, 0.1))
					_add_log_message("Picked up Gold! +10 gold")
				Item.Type.KEY:
					keys += 1
					_add_log_message("Picked up Dungeon Key!")
				Item.Type.POISON_CURE:
					poison_turns = 0
					_add_log_message("Used Antidote! Poison cured!")
				Item.Type.FIRE_BOMB:
					# Damage all enemies in 3x3 area around player
					var bomb_dmg: int = player_atk + 3
					for enemy in enemies:
						if not enemy.alive:
							continue
						var dist: int = abs(enemy.pos.x - player_pos.x) + abs(enemy.pos.y - player_pos.y)
						if dist <= 2:
							enemy.hp -= bomb_dmg
							_spawn_floating_text(enemy.pos, "-" + str(bomb_dmg), Color(1.0, 0.5, 0.1))
							if enemy.hp <= 0:
								enemy.alive = false
								kill_count += 1
								player_xp += enemy.xp_value
								_add_log_message("Fire Bomb hit " + enemy.name_str + "!")
								_handle_enemy_drops(enemy)
					_add_log_message("Fire Bomb explodes!")
				Item.Type.FROST_SCROLL:
					# Freeze all visible enemies
					for enemy in enemies:
						if not enemy.alive:
							continue
						if _is_visible(enemy.pos):
							enemy.frozen_turns = 5
							_spawn_floating_text(enemy.pos, "FROZEN", Color(0.5, 0.8, 1.0))
					_add_log_message("Frost Scroll! All visible enemies frozen!")
				Item.Type.SHADOW_STEP:
					# Teleport to random visible floor tile
					var valid_tiles: Array = []
					for y in range(map_data.height):
						for x in range(map_data.width):
							var tpos: Vector2i = Vector2i(x, y)
							if map_data.get_tile(x, y) == TileMapData.Tile.FLOOR and _is_visible(tpos):
								if not _get_enemy_at(tpos) and tpos != player_pos:
									valid_tiles.append(tpos)
					if valid_tiles.size() > 0:
						player_pos = valid_tiles[randi() % valid_tiles.size()]
						_add_log_message("Shadow Step! Teleported!")
					else:
						_add_log_message("Shadow Step failed - no valid destination!")
				Item.Type.SWORD, Item.Type.AXE, Item.Type.DAGGER, Item.Type.GREATSWORD, Item.Type.SPEAR:
					_equip_item(item, "weapon")
				Item.Type.SHIELD, Item.Type.ARMOR:
					_equip_item(item, "armor")
				Item.Type.RING_POWER, Item.Type.AMULET_LIFE, Item.Type.BOOTS_SPEED, Item.Type.RING_VAMPIRE, Item.Type.AMULET_FURY:
					_equip_item(item, "accessory")
			score = _calculate_score()
			return

func _equip_item(item: Item, slot: String) -> void:
	var old_item: Item = null
	match slot:
		"weapon":
			old_item = equipped_weapon
			equipped_weapon = item
		"armor":
			old_item = equipped_armor
			equipped_armor = item
		"accessory":
			old_item = equipped_accessory
			equipped_accessory = item
	
	_recalculate_stats()
	_add_log_message("Equipped " + item.name_str + "!")
	
	if old_item:
		old_item.pos = player_pos
		old_item.collected = false
		items.append(old_item)
		_add_log_message("Dropped " + old_item.name_str)

func _player_attack(enemy: Enemy) -> void:
	var is_crit: bool = randf() < crit_chance
	var damage: int = player_atk
	if is_crit:
		damage = int(float(player_atk) * crit_multiplier)
	
	var dmg: int = enemy.take_damage(damage)
	
	# Spawn floating damage number
	var dmg_color: Color = Color(1.0, 0.8, 0.1) if is_crit else Color(1.0, 0.3, 0.3)
	var dmg_text: String = "-" + str(dmg) if not is_crit else "-" + str(dmg) + "!"
	_spawn_floating_text(enemy.pos, dmg_text, dmg_color)
	
	if is_crit:
		_add_log_message("CRITICAL HIT! " + str(dmg) + " damage!")
	
	if enemy.alive:
		_add_log_message("Hit " + enemy.name_str + " for " + str(dmg) + "!")
		if enemy.type == Enemy.Type.BOSS_SLIME and not enemy.has_split:
			if enemy.hp <= enemy.max_hp / 2:
				enemy.has_split = true
				_boss_slime_split(enemy)
	else:
		_add_log_message("Killed " + enemy.name_str + "!")
		kill_count += 1
		player_xp += enemy.xp_value
		_spawn_floating_text(enemy.pos, "+" + str(enemy.xp_value) + " XP", Color(0.5, 0.8, 1.0))
		_add_log_message("+" + str(enemy.xp_value) + " XP")
		_check_level_up()
		score = _calculate_score()
		_handle_enemy_drops(enemy)
		if enemy.is_boss:
			_on_boss_defeated()
	
	# Lifesteal mechanic for Ring of Vampirism
	if equipped_accessory != null and equipped_accessory.type == Item.Type.RING_VAMPIRE:
		var lifesteal_amount: int = max(1, int(float(dmg) * 0.05))
		var actual_heal: int = mini(lifesteal_amount, player_max_hp - player_hp)
		if actual_heal > 0:
			player_hp += actual_heal
			_spawn_floating_text(player_pos, "+" + str(actual_heal) + " HP", Color(0.8, 0.2, 0.3))
			_add_log_message("Lifesteal: +" + str(actual_heal) + " HP")

func _handle_enemy_drops(enemy: Enemy) -> void:
	if enemy.guaranteed_drop >= 0:
		var drop: Item = Item.new()
		drop.setup(enemy.guaranteed_drop, enemy.pos)
		items.append(drop)
		_add_log_message(enemy.name_str + " dropped " + drop.name_str + "!")
	elif enemy.drop_chance > 0 and randf() < enemy.drop_chance:
		var drop_types: Array = []
		if current_floor >= 3:
			drop_types.append(Item.Type.SWORD)
		if current_floor >= 5:
			drop_types.append(Item.Type.SHIELD)
			drop_types.append(Item.Type.DAGGER)
		if current_floor >= 7:
			drop_types.append(Item.Type.AXE)
			drop_types.append(Item.Type.ARMOR)
		if current_floor >= 10:
			drop_types.append(Item.Type.RING_POWER)
			drop_types.append(Item.Type.AMULET_LIFE)
		
		if drop_types.size() > 0:
			var drop: Item = Item.new()
			drop.setup(drop_types[randi() % drop_types.size()], enemy.pos)
			items.append(drop)
			_add_log_message(enemy.name_str + " dropped " + drop.name_str + "!")

func _check_traps() -> void:
	for trap in traps:
		if trap.triggered:
			continue
		if trap.pos == player_pos:
			trap.visible = true
			trap.triggered = true
			_trigger_trap(trap)
			if trap.is_one_shot():
				traps.erase(trap)
			break

func _trigger_trap(trap: Trap) -> void:
	match trap.type:
		Trap.Type.SPIKES:
			var dmg: int = maxi(1, 3 - player_def)
			player_hp -= dmg
			damage_flash_timer = 0.3
			_add_log_message("Spike trap! -" + str(dmg) + " HP")
		Trap.Type.POISON_DART:
			var dmg: int = maxi(1, 2 - player_def)
			player_hp -= dmg
			poison_turns = 5
			damage_flash_timer = 0.3
			_add_log_message("Poison dart! -" + str(dmg) + " HP, poisoned!")
		Trap.Type.FIRE_VENT:
			var dmg: int = maxi(1, 4 - player_def)
			player_hp -= dmg
			burn_turns = 3
			damage_flash_timer = 0.3
			_add_log_message("Fire vent! -" + str(dmg) + " HP, burning!")
		Trap.Type.TELEPORT:
			_teleport_random()
			_add_log_message("Teleport trap! You're somewhere else...")
		Trap.Type.ICE_PATCH:
			slow_turns = 4
			_add_log_message("Ice patch! Slowed for 4 turns!")
		Trap.Type.LAVA_CRACK:
			var dmg: int = maxi(1, 5 - player_def)
			player_hp -= dmg
			burn_turns = 5
			damage_flash_timer = 0.3
			_add_log_message("Lava crack! -" + str(dmg) + " HP, burning for 5 turns!")
		Trap.Type.SHADOW_PIT:
			var dmg: int = maxi(1, 3 - player_def)
			player_hp -= dmg
			_teleport_random()
			damage_flash_timer = 0.3
			_add_log_message("Shadow pit! -" + str(dmg) + " HP, teleported!")
		Trap.Type.SPIRIT_WISP:
			var xp_drain: int = mini(player_xp, 10)
			player_xp -= xp_drain
			_add_log_message("Spirit wisp! -" + str(xp_drain) + " XP drained!")
	if player_hp <= 0:
		player_hp = 0
		game_over = true
		score = _calculate_score()
		_save_on_death()

func _teleport_random() -> void:
	var attempts: int = 0
	while attempts < 100:
		attempts += 1
		var new_pos: Vector2i = map_data.get_random_floor_tile()
		if _get_enemy_at(new_pos) == null and new_pos != player_pos:
			player_pos = new_pos
			_update_visibility()
			_update_camera()
			return
