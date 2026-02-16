extends Node2D

const TILE_SIZE := 32

var map_data: TileMapData
var generator: DungeonGenerator
var player_pos: Vector2i
var current_floor: int = 1
var camera_offset: Vector2 = Vector2.ZERO
var message: String = ""
var message_timer: float = 0.0

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
	
	player_pos = new_pos
	
	# Check stairs
	var tile: int = map_data.get_tile(player_pos.x, player_pos.y)
	if tile == TileMapData.Tile.STAIRS_DOWN:
		current_floor += 1
		_generate_floor()
		return
	
	_update_camera()
	queue_redraw()

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
	
	# Draw tiles
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			var tile: int = map_data.get_tile(x, y)
			var rect: Rect2 = Rect2(
				float(x * TILE_SIZE) + camera_offset.x,
				float(y * TILE_SIZE) + camera_offset.y,
				float(TILE_SIZE - 1),
				float(TILE_SIZE - 1)
			)
			
			if tile == TileMapData.Tile.WALL:
				draw_rect(rect, color_wall)
			elif tile == TileMapData.Tile.FLOOR:
				draw_rect(rect, color_floor)
			elif tile == TileMapData.Tile.STAIRS_DOWN:
				draw_rect(rect, color_stairs)
			elif tile == TileMapData.Tile.DOOR:
				draw_rect(rect, Color(0.6, 0.4, 0.1))
	
	# Draw player
	var player_screen: Vector2 = Vector2(
		float(player_pos.x * TILE_SIZE) + camera_offset.x + float(TILE_SIZE) / 2.0,
		float(player_pos.y * TILE_SIZE) + camera_offset.y + float(TILE_SIZE) / 2.0
	)
	draw_circle(player_screen, float(TILE_SIZE) * 0.4, color_player)
	
	# HUD background
	draw_rect(Rect2(0, 0, viewport_w, 36), color_hud_bg)
	
	# HUD text
	var hud_text: String = "Floor: " + str(current_floor) + "  |  Depths of Ruin"
	draw_string(ThemeDB.fallback_font, Vector2(10, 24), hud_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color_text)
	
	# Message
	if message != "":
		var msg_y: float = float(viewport_h) / 2.0 - 60.0
		var msg_size: int = 24
		draw_string(ThemeDB.fallback_font, Vector2(float(viewport_w) / 2.0 - float(message.length()) * 6.0, msg_y), message, HORIZONTAL_ALIGNMENT_CENTER, viewport_w, msg_size, color_stairs)
