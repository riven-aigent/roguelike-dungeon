class_name DungeonGenerator

const MIN_ROOM_SIZE := 5
const MAX_ROOM_SIZE := 12
const MIN_LEAF_SIZE := 8
const MAX_DEPTH := 5

var map_data: TileMapData
var rooms: Array[Rect2i] = []

class BSPLeaf:
	var rect: Rect2i
	var left: BSPLeaf
	var right: BSPLeaf
	var room: Rect2i
	
	func _init(r: Rect2i) -> void:
		rect = r
		left = null
		right = null
		room = Rect2i()

func generate(width: int = 60, height: int = 60) -> TileMapData:
	map_data = TileMapData.new(width, height)
	rooms.clear()
	
	# Create root leaf covering the entire map (with 1-tile border)
	var root := BSPLeaf.new(Rect2i(1, 1, width - 2, height - 2))
	
	# Split recursively
	_split(root, 0)
	
	# Create rooms in leaves
	_create_rooms(root)
	
	# Connect rooms with corridors
	_create_corridors(root)
	
	# Place stairs down in a random room (last room preferably)
	if rooms.size() > 1:
		var stairs_room := rooms[rooms.size() - 1]
		var sx := stairs_room.position.x + randi() % max(stairs_room.size.x, 1)
		var sy := stairs_room.position.y + randi() % max(stairs_room.size.y, 1)
		map_data.set_tile(sx, sy, TileMapData.Tile.STAIRS_DOWN)
	
	return map_data

func _split(leaf: BSPLeaf, depth: int) -> void:
	if depth >= MAX_DEPTH:
		return
	
	var w := leaf.rect.size.x
	var h := leaf.rect.size.y
	
	# Don't split if too small
	if w < MIN_LEAF_SIZE * 2 and h < MIN_LEAF_SIZE * 2:
		return
	
	# Decide split direction
	var split_h: bool
	if w < MIN_LEAF_SIZE * 2:
		split_h = true
	elif h < MIN_LEAF_SIZE * 2:
		split_h = false
	else:
		split_h = randf() > 0.5
	
	if split_h:
		# Horizontal split
		if h < MIN_LEAF_SIZE * 2:
			return
		var split_y := MIN_LEAF_SIZE + randi() % max(h - MIN_LEAF_SIZE * 2, 1)
		leaf.left = BSPLeaf.new(Rect2i(leaf.rect.position.x, leaf.rect.position.y, w, split_y))
		leaf.right = BSPLeaf.new(Rect2i(leaf.rect.position.x, leaf.rect.position.y + split_y, w, h - split_y))
	else:
		# Vertical split
		if w < MIN_LEAF_SIZE * 2:
			return
		var split_x := MIN_LEAF_SIZE + randi() % max(w - MIN_LEAF_SIZE * 2, 1)
		leaf.left = BSPLeaf.new(Rect2i(leaf.rect.position.x, leaf.rect.position.y, split_x, h))
		leaf.right = BSPLeaf.new(Rect2i(leaf.rect.position.x + split_x, leaf.rect.position.y, w - split_x, h))
	
	_split(leaf.left, depth + 1)
	_split(leaf.right, depth + 1)

func _create_rooms(leaf: BSPLeaf) -> void:
	if leaf.left != null and leaf.right != null:
		_create_rooms(leaf.left)
		_create_rooms(leaf.right)
		return
	
	# Leaf node: create a room
	var lw := leaf.rect.size.x
	var lh := leaf.rect.size.y
	
	var room_w := MIN_ROOM_SIZE + randi() % max(min(lw - 2, MAX_ROOM_SIZE) - MIN_ROOM_SIZE + 1, 1)
	var room_h := MIN_ROOM_SIZE + randi() % max(min(lh - 2, MAX_ROOM_SIZE) - MIN_ROOM_SIZE + 1, 1)
	
	var room_x := leaf.rect.position.x + randi() % max(lw - room_w, 1)
	var room_y := leaf.rect.position.y + randi() % max(lh - room_h, 1)
	
	leaf.room = Rect2i(room_x, room_y, room_w, room_h)
	rooms.append(leaf.room)
	
	# Carve the room
	for y in range(room_y, room_y + room_h):
		for x in range(room_x, room_x + room_w):
			map_data.set_tile(x, y, TileMapData.Tile.FLOOR)

func _get_room_center(leaf: BSPLeaf) -> Vector2i:
	if leaf.room.size.x > 0 and leaf.room.size.y > 0:
		return Vector2i(
			leaf.room.position.x + leaf.room.size.x / 2,
			leaf.room.position.y + leaf.room.size.y / 2
		)
	if leaf.left != null:
		return _get_room_center(leaf.left)
	if leaf.right != null:
		return _get_room_center(leaf.right)
	return Vector2i(leaf.rect.position.x + leaf.rect.size.x / 2, leaf.rect.position.y + leaf.rect.size.y / 2)

func _create_corridors(leaf: BSPLeaf) -> void:
	if leaf.left == null or leaf.right == null:
		return
	
	_create_corridors(leaf.left)
	_create_corridors(leaf.right)
	
	var center_a := _get_room_center(leaf.left)
	var center_b := _get_room_center(leaf.right)
	
	# L-shaped corridor
	if randf() > 0.5:
		_carve_h_corridor(center_a.x, center_b.x, center_a.y)
		_carve_v_corridor(center_a.y, center_b.y, center_b.x)
	else:
		_carve_v_corridor(center_a.y, center_b.y, center_a.x)
		_carve_h_corridor(center_a.x, center_b.x, center_b.y)

func _carve_h_corridor(x1: int, x2: int, y: int) -> void:
	var start := min(x1, x2)
	var end := max(x1, x2)
	for x in range(start, end + 1):
		if map_data.get_tile(x, y) == TileMapData.Tile.WALL:
			map_data.set_tile(x, y, TileMapData.Tile.FLOOR)

func _carve_v_corridor(y1: int, y2: int, x: int) -> void:
	var start := min(y1, y2)
	var end := max(y1, y2)
	for y in range(start, end + 1):
		if map_data.get_tile(x, y) == TileMapData.Tile.WALL:
			map_data.set_tile(x, y, TileMapData.Tile.FLOOR)
