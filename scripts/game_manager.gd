extends Node2D

const TILE_SIZE := 32
const FOG_RADIUS := 6
const FOG_RADIUS_SQ := FOG_RADIUS * FOG_RADIUS

var map_data: TileMapData
var generator: DungeonGenerator
var player_pos: Vector2i
var current_floor: int = 1
var camera_offset: Vector2 = Vector2.ZERO
var message: String = ""
var message_timer: float = 0.0

# Player stats
var player_hp: int = 20
var player_max_hp: int = 20
var player_atk: int = 3
var player_def: int = 1
var kill_count: int = 0

# Enemies
var enemies: Array = []  # Array of Enemy

# Items
var items: Array = []  # Array of Item
var gold_collected: int = 0

# Score
var score: int = 0

# Fog of war
var revealed: Dictionary = {}   # Vector2i -> true (currently visible)
var explored: Dictionary = {}   # Vector2i -> true (previously seen)
var stairs_found: Dictionary = {} # Vector2i -> true (stairs discovered)

# Game state
var game_over: bool = false
var damage_flash_timer: float = 0.0

# Touch input
var touch_start: Vector2 = Vector2.ZERO
var is_touching: bool = false
const SWIPE_THRESHOLD := 30.0

# Colors
var color_wall: Color = Color(0.25, 0.15, 0.08)
var color_floor: Color = Color(0.2, 0.2, 0.22)
var color_stairs: Color = Color(0.0, 0.8, 0.8)
var color_player: Color = Color(0.2, 0.9, 0.2)
var color_bg: Color = Color(0.05, 0.05, 0.07)
var color_text: Color = Color(0.9, 0.9, 0.8)
var color_hud_bg: Color = Color(0.0, 0.0, 0.0, 0.7)
var color_fog: Color = Color(0.0, 0.0, 0.0)  # Unexplored
var color_dim: float = 0.45  # Multiplier for explored-but-not-visible tiles

# Viewport
var viewport_w: int = 480
var viewport_h: int = 800

# Minimap
const MINIMAP_SIZE := 120
const MINIMAP_MARGIN := 8
var minimap_scale: float = 2.0

func _ready() -> void:
	generator = DungeonGenerator.new()
	_generate_floor()

func _generate_floor() -> void:
	map_data = generator.generate(60, 60)
	player_pos = map_data.get_random_floor_tile()
	# Reset fog for new floor
	revealed.clear()
	explored.clear()
	stairs_found.clear()
	_spawn_enemies()
	_spawn_items()
	_update_visibility()
	_update_camera()
	_show_message("Floor " + str(current_floor))
	queue_redraw()

func _get_types_for_floor(floor_num: int) -> Array:
	var types: Array = []
	if floor_num >= 1:
		types.append(Enemy.Type.SLIME)
		types.append(Enemy.Type.BAT)
	if floor_num >= 3:
		types.append(Enemy.Type.SKELETON)
	if floor_num >= 5:
		types.append(Enemy.Type.ORC)
	if floor_num > 3:
		types.erase(Enemy.Type.SLIME)
	if floor_num > 5:
		types.erase(Enemy.Type.BAT)
	return types

func _spawn_enemies() -> void:
	enemies.clear()
	var count: int = 3 + (randi() % 4)  # 3-6 enemies
	var valid_types: Array = _get_types_for_floor(current_floor)
	if valid_types.is_empty():
		return

	var occupied: Dictionary = {}
	occupied[player_pos] = true
	# Mark stairs as occupied
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
		var t: int = valid_types[randi() % valid_types.size()]
		var enemy: Enemy = Enemy.new()
		enemy.setup(t, pos)
		enemies.append(enemy)
		occupied[pos] = true

func _spawn_items() -> void:
	items.clear()
	var count: int = 2 + (randi() % 3)  # 2-4 items

	var occupied: Dictionary = {}
	occupied[player_pos] = true
	for enemy in enemies:
		occupied[enemy.pos] = true
	for y in range(map_data.height):
		for x in range(map_data.width):
			if map_data.get_tile(x, y) == TileMapData.Tile.STAIRS_DOWN:
				occupied[Vector2i(x, y)] = true

	var item_types: Array = [Item.Type.HEALTH_POTION, Item.Type.STRENGTH_POTION, Item.Type.SHIELD_SCROLL, Item.Type.GOLD]
	# Weight: health potions and gold more common
	var weighted: Array = [
		Item.Type.HEALTH_POTION, Item.Type.HEALTH_POTION,
		Item.Type.GOLD, Item.Type.GOLD, Item.Type.GOLD,
		Item.Type.STRENGTH_POTION,
		Item.Type.SHIELD_SCROLL
	]

	var attempts: int = 0
	while items.size() < count and attempts < 200:
		attempts += 1
		var pos: Vector2i = map_data.get_random_floor_tile()
		if occupied.has(pos):
			continue
		var t: int = weighted[randi() % weighted.size()]
		var item: Item = Item.new()
		item.setup(t, pos)
		items.append(item)
		occupied[pos] = true

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
					# Track stairs discovery
					if map_data.get_tile(tx, ty) == TileMapData.Tile.STAIRS_DOWN:
						stairs_found[tpos] = true

func _is_visible(pos: Vector2i) -> bool:
	return revealed.has(pos)

func _is_explored(pos: Vector2i) -> bool:
	return explored.has(pos)

func _show_message(msg: String) -> void:
	message = msg
	message_timer = 2.5

func _calculate_score() -> int:
	return kill_count * 10 + gold_collected + current_floor * 5

func _process(delta: float) -> void:
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			message = ""
		queue_redraw()
	if damage_flash_timer > 0:
		damage_flash_timer -= delta
		if damage_flash_timer <= 0:
			damage_flash_timer = 0.0
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	# Game over: any tap or key restarts
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

	# Touch / swipe
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			touch_start = touch_event.position
			is_touching = true
		else:
			is_touching = false
	elif event is InputEventScreenDrag and is_touching:
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

	if dir != Vector2i.ZERO:
		_try_move(dir)

func _try_move(dir: Vector2i) -> void:
	var new_pos: Vector2i = player_pos + dir

	if not map_data.is_walkable(new_pos.x, new_pos.y):
		return

	# Check if enemy is at new_pos (bump attack)
	var target_enemy: Enemy = _get_enemy_at(new_pos)
	if target_enemy != null:
		_player_attack(target_enemy)
		_enemy_turn()
		_update_visibility()
		_update_camera()
		queue_redraw()
		return

	player_pos = new_pos

	# Check for items at this position
	_check_item_pickup()

	# Check stairs
	var tile: int = map_data.get_tile(player_pos.x, player_pos.y)
	if tile == TileMapData.Tile.STAIRS_DOWN:
		current_floor += 1
		_generate_floor()
		return

	# Enemy turn after player moves
	_enemy_turn()
	_update_visibility()
	_update_camera()
	score = _calculate_score()
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
					_show_message("Picked up Health Potion! +" + str(heal) + " HP")
				Item.Type.STRENGTH_POTION:
					player_atk += 1
					_show_message("Picked up Strength Potion! +1 ATK")
				Item.Type.SHIELD_SCROLL:
					player_def += 1
					_show_message("Picked up Shield Scroll! +1 DEF")
				Item.Type.GOLD:
					gold_collected += 10
					_show_message("Picked up Gold! +10 score")
			score = _calculate_score()
			return

func _player_attack(enemy: Enemy) -> void:
	var dmg: int = enemy.take_damage(player_atk)
	if enemy.alive:
		_show_message("Hit " + enemy.name_str + " for " + str(dmg) + "!")
	else:
		_show_message("Killed " + enemy.name_str + "! (+" + str(dmg) + ")")
		kill_count += 1
		score = _calculate_score()

func _enemy_turn() -> void:
	for enemy in enemies:
		if not enemy.alive:
			continue
		var dist: int = absi(enemy.pos.x - player_pos.x) + absi(enemy.pos.y - player_pos.y)
		var move_dir: Vector2i = Vector2i.ZERO

		if dist <= 5:
			# Move toward player
			move_dir = _get_chase_dir(enemy.pos, player_pos)
		else:
			# Random movement (50% chance to move)
			if randf() < 0.5:
				var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
				move_dir = dirs[randi() % 4]

		if move_dir == Vector2i.ZERO:
			continue

		var new_pos: Vector2i = enemy.pos + move_dir

		# Check if new_pos is the player (bump attack)
		if new_pos == player_pos:
			_enemy_attack(enemy)
			continue

		# Check walkable and no other enemy there
		if map_data.is_walkable(new_pos.x, new_pos.y) and _get_enemy_at(new_pos) == null:
			enemy.pos = new_pos

func _enemy_attack(enemy: Enemy) -> void:
	var dmg: int = maxi(1, enemy.atk - player_def)
	player_hp -= dmg
	damage_flash_timer = 0.2
	_show_message(enemy.name_str + " hits you for " + str(dmg) + "!")
	if player_hp <= 0:
		player_hp = 0
		game_over = true
		score = _calculate_score()

func _get_chase_dir(from: Vector2i, to: Vector2i) -> Vector2i:
	var dx: int = to.x - from.x
	var dy: int = to.y - from.y
	# Prefer the axis with greater distance
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

	# Check if that direction is walkable
	var test: Vector2i = from + dir
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
		if map_data.is_walkable(alt_test.x, alt_test.y):
			return alt_dir

	return Vector2i.ZERO

func _get_enemy_at(pos: Vector2i) -> Enemy:
	for enemy in enemies:
		if enemy.alive and enemy.pos == pos:
			return enemy
	return null

func _restart_game() -> void:
	game_over = false
	current_floor = 1
	player_hp = player_max_hp
	player_atk = 3
	player_def = 1
	kill_count = 0
	gold_collected = 0
	score = 0
	damage_flash_timer = 0.0
	_generate_floor()

func _update_camera() -> void:
	camera_offset = Vector2(
		float(viewport_w) / 2.0 - float(player_pos.x * TILE_SIZE) - float(TILE_SIZE) / 2.0,
		float(viewport_h) / 2.0 - float(player_pos.y * TILE_SIZE) - float(TILE_SIZE) / 2.0
	)

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, viewport_w, viewport_h), color_bg)

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
				# Completely hidden: draw black
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
				# Stairs: always show if discovered, even in fog
				if stairs_found.has(tpos):
					tile_color = color_stairs
				else:
					tile_color = color_floor
			elif tile == TileMapData.Tile.DOOR:
				tile_color = Color(0.6, 0.4, 0.1)
			else:
				tile_color = color_floor

			# Dim explored-but-not-visible tiles
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
				# Red cross/plus
				var s: float = float(TILE_SIZE) * 0.12
				var l: float = float(TILE_SIZE) * 0.3
				draw_rect(Rect2(icx - s, icy - l, s * 2.0, l * 2.0), icolor)
				draw_rect(Rect2(icx - l, icy - s, l * 2.0, s * 2.0), icolor)
			Item.Type.STRENGTH_POTION:
				# Orange up-arrow
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
			Item.Type.SHIELD_SCROLL:
				# Blue square with border feel
				var s: float = float(TILE_SIZE) * 0.28
				draw_rect(Rect2(icx - s, icy - s, s * 2.0, s * 2.0), icolor)
				draw_rect(Rect2(icx - s * 0.6, icy - s * 0.6, s * 1.2, s * 1.2), Color(0.15, 0.25, 0.5))
			Item.Type.GOLD:
				# Yellow dot
				draw_circle(Vector2(icx, icy), float(TILE_SIZE) * 0.22, icolor)

	# Draw enemies (only if visible)
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

		# Only draw if on screen
		if ecx < -TILE_SIZE or ecx > viewport_w + TILE_SIZE:
			continue
		if ecy < -TILE_SIZE or ecy > viewport_h + TILE_SIZE:
			continue

		match enemy.type:
			Enemy.Type.SLIME:
				draw_circle(Vector2(ecx, ecy), float(TILE_SIZE) * 0.35, ecolor)
			Enemy.Type.BAT:
				var s: float = float(TILE_SIZE) * 0.35
				var pts: PackedVector2Array = PackedVector2Array([
					Vector2(ecx, ecy - s),
					Vector2(ecx + s, ecy),
					Vector2(ecx, ecy + s),
					Vector2(ecx - s, ecy)
				])
				draw_colored_polygon(pts, ecolor)
			Enemy.Type.SKELETON:
				var s: float = float(TILE_SIZE) * 0.3
				draw_rect(Rect2(ecx - s, ecy - s, s * 2.0, s * 2.0), ecolor)
			Enemy.Type.ORC:
				draw_circle(Vector2(ecx, ecy), float(TILE_SIZE) * 0.42, ecolor)

		# Enemy HP bar (small bar above enemy)
		if enemy.hp < enemy.max_hp:
			var bar_w: float = float(TILE_SIZE - 4)
			var bar_h: float = 3.0
			var bar_x: float = ex + 2.0
			var bar_y: float = ey - 4.0
			var hp_ratio: float = float(enemy.hp) / float(enemy.max_hp)
			draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.3, 0.0, 0.0))
			draw_rect(Rect2(bar_x, bar_y, bar_w * hp_ratio, bar_h), Color(0.9, 0.1, 0.1))

	# Draw player
	var player_color: Color = color_player
	if damage_flash_timer > 0:
		player_color = Color(1.0, 0.2, 0.2)
	var player_screen: Vector2 = Vector2(
		float(player_pos.x * TILE_SIZE) + camera_offset.x + float(TILE_SIZE) / 2.0,
		float(player_pos.y * TILE_SIZE) + camera_offset.y + float(TILE_SIZE) / 2.0
	)
	draw_circle(player_screen, float(TILE_SIZE) * 0.4, player_color)

	# === HUD ===
	var hud_h: float = 62.0
	draw_rect(Rect2(0, 0, viewport_w, hud_h), color_hud_bg)

	# HUD line 1: Floor | Kills | Score
	var hud_text: String = "Floor: " + str(current_floor) + "  |  Kills: " + str(kill_count) + "  |  Score: " + str(score)
	draw_string(ThemeDB.fallback_font, Vector2(10, 18), hud_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color_text)

	# HP bar
	var hp_label: String = "HP: " + str(player_hp) + "/" + str(player_max_hp)
	draw_string(ThemeDB.fallback_font, Vector2(10, 36), hp_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color_text)

	var bar_start_x: float = 100.0
	var bar_w: float = float(viewport_w) - bar_start_x - 10.0
	var bar_h: float = 14.0
	var bar_y: float = 25.0
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

	# ATK/DEF display
	var stat_text: String = "ATK:" + str(player_atk) + " DEF:" + str(player_def)
	draw_string(ThemeDB.fallback_font, Vector2(10, 56), stat_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.6))

	# Gold display next to stats
	var gold_text: String = "Gold:" + str(gold_collected)
	draw_string(ThemeDB.fallback_font, Vector2(160, 56), gold_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.85, 0.1))

	# Message
	if message != "":
		var msg_y: float = hud_h + 18.0
		draw_rect(Rect2(0, msg_y - 16.0, viewport_w, 22.0), Color(0.0, 0.0, 0.0, 0.6))
		draw_string(ThemeDB.fallback_font, Vector2(10, msg_y), message, HORIZONTAL_ALIGNMENT_LEFT, viewport_w - 20, 14, color_stairs)

	# === MINIMAP ===
	_draw_minimap()

	# Game over overlay
	if game_over:
		draw_rect(Rect2(0, 0, viewport_w, viewport_h), Color(0.0, 0.0, 0.0, 0.75))

		var title: String = "YOU DIED"
		var title_w: float = float(title.length()) * 14.0
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - title_w / 2.0, float(viewport_h) / 2.0 - 60.0), title, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 28, Color(0.9, 0.15, 0.15))

		var score_text: String = "Score: " + str(score)
		var floor_text: String = "Reached Floor " + str(current_floor)
		var kills_text: String = "Enemies Slain: " + str(kill_count)
		var gold_text2: String = "Gold: " + str(gold_collected)
		var restart_text: String = "Tap or press any key to restart"

		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - float(score_text.length()) * 6.0, float(viewport_h) / 2.0 - 20.0), score_text, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 22, Color(1.0, 0.85, 0.1))
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - float(floor_text.length()) * 5.0, float(viewport_h) / 2.0 + 15.0), floor_text, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 18, color_text)
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - float(kills_text.length()) * 5.0, float(viewport_h) / 2.0 + 40.0), kills_text, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 18, color_text)
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - float(gold_text2.length()) * 5.0, float(viewport_h) / 2.0 + 65.0), gold_text2, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 18, color_text)
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - float(restart_text.length()) * 4.0, float(viewport_h) / 2.0 + 110.0), restart_text, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, 14, Color(0.6, 0.6, 0.5))

func _draw_minimap() -> void:
	# Position: top-right corner below HUD
	var mm_x: float = float(viewport_w - MINIMAP_SIZE - MINIMAP_MARGIN)
	var mm_y: float = 66.0  # Below HUD

	# Background
	draw_rect(Rect2(mm_x - 2, mm_y - 2, MINIMAP_SIZE + 4, MINIMAP_SIZE + 4), Color(0.3, 0.3, 0.3, 0.8))
	draw_rect(Rect2(mm_x, mm_y, MINIMAP_SIZE, MINIMAP_SIZE), Color(0.0, 0.0, 0.0, 0.9))

	# Scale: map tiles to minimap pixels
	minimap_scale = float(MINIMAP_SIZE) / float(maxi(map_data.width, map_data.height))

	# Draw explored tiles
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

	# Player dot (larger, bright green)
	var pp_x: float = mm_x + float(player_pos.x) * minimap_scale
	var pp_y: float = mm_y + float(player_pos.y) * minimap_scale
	var dot_size: float = maxf(minimap_scale * 1.5, 2.5)
	draw_rect(Rect2(pp_x - dot_size * 0.25, pp_y - dot_size * 0.25, dot_size, dot_size), Color(0.2, 1.0, 0.2))
