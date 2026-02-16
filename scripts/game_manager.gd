extends Node2D

const TILE_SIZE := 32

var map_data: TileMapData
var generator: DungeonGenerator
var player_pos: Vector2i
var current_floor: int = 1
var camera_offset: Vector2
var message: String = ""
var message_timer: float = 0.0

# Touch input
var touch_start: Vector2 = Vector2.ZERO
var is_touching: bool = false
const SWIPE_THRESHOLD := 30.0

# Colors
var color_wall := Color(0.25, 0.15, 0.08)
var color_floor := Color(0.2, 0.2, 0.22)
var color_stairs := Color(0.0, 0.8, 0.8)
var color_player := Color(0.2, 0.9, 0.2)
var color_bg := Color(0.05, 0.05, 0.07)
var color_text := Color(0.9, 0.9, 0.8)
var color_hud_bg := Color(0.0, 0.0, 0.0, 0.7)

# Viewport
var viewport_w: int = 480
var viewport_h: int = 800

func _ready() -> void:
	generator = DungeonGenerator.new()
	_generate_floor()

func _generate_floor() -> void:
	map_data = generator.generate(60, 60)
	player_pos = map_data.get_random_floor_tile()
	_update_camera()
	_show_message("Floor " + str(current_floor))
	queue_redraw()

func _show_message(msg: String) -> void:
	message = msg
	message_timer = 2.5

func _process(delta: float) -> void:
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			message = ""
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var moved := false
	var dir := Vector2i.ZERO
	
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
		if event.pressed:
			touch_start = event.position
			is_touching = true
		else:
			is_touching = false
	elif event is InputEventScreenDrag and is_touching:
		var delta_pos: Vector2 = event.position - touch_start
		if delta_pos.length() > SWIPE_THRESHOLD:
			is_touching = false
			if abs(delta_pos.x) > abs(delta_pos.y):
				dir = Vector2i(1, 0) if delta_pos.x > 0 else Vector2i(-1, 0)
			else:
				dir = Vector2i(0, 1) if delta_pos.y > 0 else Vector2i(0, -1)
	
	if dir != Vector2i.ZERO:
		_try_move(dir)

func _try_move(dir: Vector2i) -> void:
	var new_pos := player_pos + dir
	
	if not map_data.is_walkable(new_pos.x, new_pos.y):
		return
	
	player_pos = new_pos
	
	# Check stairs
	var tile := map_data.get_tile(player_pos.x, player_pos.y)
	if tile == TileMapData.Tile.STAIRS_DOWN:
		current_floor += 1
		_generate_floor()
		return
	
	_update_camera()
	queue_redraw()

func _update_camera() -> void:
	camera_offset = Vector2(
		viewport_w / 2.0 - player_pos.x * TILE_SIZE - TILE_SIZE / 2.0,
		viewport_h / 2.0 - player_pos.y * TILE_SIZE - TILE_SIZE / 2.0
	)

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, viewport_w, viewport_h), color_bg)
	
	# Calculate visible tile range
	var start_x := int((-camera_offset.x) / TILE_SIZE) - 1
	var start_y := int((-camera_offset.y) / TILE_SIZE) - 1
	var end_x := start_x + int(viewport_w / TILE_SIZE) + 3
	var end_y := start_y + int(viewport_h / TILE_SIZE) + 3
	
	start_x = max(start_x, 0)
	start_y = max(start_y, 0)
	end_x = min(end_x, map_data.width)
	end_y = min(end_y, map_data.height)
	
	# Draw tiles
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var tile := map_data.get_tile(x, y)
			var rect := Rect2(
				x * TILE_SIZE + camera_offset.x,
				y * TILE_SIZE + camera_offset.y,
				TILE_SIZE - 1,
				TILE_SIZE - 1
			)
			
			match tile:
				TileMapData.Tile.WALL:
					draw_rect(rect, color_wall)
				TileMapData.Tile.FLOOR:
					draw_rect(rect, color_floor)
				TileMapData.Tile.STAIRS_DOWN:
					draw_rect(rect, color_stairs)
				TileMapData.Tile.DOOR:
					draw_rect(rect, Color(0.6, 0.4, 0.1))
	
	# Draw player
	var player_screen := Vector2(
		player_pos.x * TILE_SIZE + camera_offset.x + TILE_SIZE / 2.0,
		player_pos.y * TILE_SIZE + camera_offset.y + TILE_SIZE / 2.0
	)
	draw_circle(player_screen, TILE_SIZE * 0.4, color_player)
	
	# HUD background
	draw_rect(Rect2(0, 0, viewport_w, 36), color_hud_bg)
	
	# HUD text
	var hud_text := "Floor: " + str(current_floor) + "  |  Depths of Ruin"
	draw_string(ThemeDB.fallback_font, Vector2(10, 24), hud_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color_text)
	
	# Message
	if message != "":
		var msg_y := viewport_h / 2.0 - 60
		var msg_size := 24
		draw_string(ThemeDB.fallback_font, Vector2(viewport_w / 2.0 - message.length() * 6, msg_y), message, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, msg_size, color_stairs)
