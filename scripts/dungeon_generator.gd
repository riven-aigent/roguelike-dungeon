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

func generate(width: int = 60, height: int = 60, is_shop_floor: bool = false) -> TileMapData:
	map_data = TileMapData.new(width, height)
	rooms.clear()
	
	var root: BSPLeaf = BSPLeaf.new(Rect2i(1, 1, width - 2, height - 2))
	
	_split(root, 0)
	_create_rooms(root)
	_create_corridors(root)
	
	# Place stairs down in last room
	if rooms.size() > 1:
		var stairs_room: Rect2i = rooms[rooms.size() - 1]
		var sx: int = stairs_room.position.x + (randi() % maxi(stairs_room.size.x, 1))
		var sy: int = stairs_room.position.y + (randi() % maxi(stairs_room.size.y, 1))
		map_data.set_tile(sx, sy, TileMapData.Tile.STAIRS_DOWN)
	# Place shop tile if this is a shop floor
	if is_shop_floor:
		_place_shop_tile()
	
	return map_data

func generate_boss_floor() -> TileMapData:
	# Boss floor: single 20x20 room centered in a 24x24 map
	var bw: int = 24
	var bh: int = 24
	map_data = TileMapData.new(bw, bh)
	rooms.clear()
	
	# Carve a 20x20 room in the center
	var room_x: int = 2
	var room_y: int = 2
	var room_w: int = 20
	var room_h: int = 20
	
	for y in range(room_y, room_y + room_h):
		for x in range(room_x, room_x + room_w):
			map_data.set_tile(x, y, TileMapData.Tile.FLOOR)
	
	rooms.append(Rect2i(room_x, room_y, room_w, room_h))
	
	# No stairs initially; stairs appear after boss is killed
	return map_data

func get_boss_room_center() -> Vector2i:
	# Center of the 20x20 room in 24x24 map
	return Vector2i(12, 12)

func get_boss_player_start() -> Vector2i:
	# Player starts near the bottom of the room
	return Vector2i(12, 19)

func _split(leaf: BSPLeaf, depth: int) -> void:
	if depth >= MAX_DEPTH:
		return
	
	var w: int = leaf.rect.size.x
	var h: int = leaf.rect.size.y
	
	if w < MIN_LEAF_SIZE * 2 and h < MIN_LEAF_SIZE * 2:
		return
	
	var split_h: bool
	if w < MIN_LEAF_SIZE * 2:
		split_h = true
	elif h < MIN_LEAF_SIZE * 2:
		split_h = false
	else:
		split_h = randf() > 0.5
	
	if split_h:
		if h < MIN_LEAF_SIZE * 2:
			return
		var split_y: int = MIN_LEAF_SIZE + (randi() % maxi(h - MIN_LEAF_SIZE * 2, 1))
		leaf.left = BSPLeaf.new(Rect2i(leaf.rect.position.x, leaf.rect.position.y, w, split_y))
		leaf.right = BSPLeaf.new(Rect2i(leaf.rect.position.x, leaf.rect.position.y + split_y, w, h - split_y))
	else:
		if w < MIN_LEAF_SIZE * 2:
			return
		var split_x: int = MIN_LEAF_SIZE + (randi() % maxi(w - MIN_LEAF_SIZE * 2, 1))
		leaf.left = BSPLeaf.new(Rect2i(leaf.rect.position.x, leaf.rect.position.y, split_x, h))
		leaf.right = BSPLeaf.new(Rect2i(leaf.rect.position.x + split_x, leaf.rect.position.y, w - split_x, h))
	
	_split(leaf.left, depth + 1)
	_split(leaf.right, depth + 1)

func _create_rooms(leaf: BSPLeaf) -> void:
	if leaf.left != null and leaf.right != null:
		_create_rooms(leaf.left)
		_create_rooms(leaf.right)
		return
	
	var lw: int = leaf.rect.size.x
	var lh: int = leaf.rect.size.y
	
	var room_w: int = MIN_ROOM_SIZE + (randi() % maxi(mini(lw - 2, MAX_ROOM_SIZE) - MIN_ROOM_SIZE + 1, 1))
	var room_h: int = MIN_ROOM_SIZE + (randi() % maxi(mini(lh - 2, MAX_ROOM_SIZE) - MIN_ROOM_SIZE + 1, 1))
	
	var room_x: int = leaf.rect.position.x + (randi() % maxi(lw - room_w, 1))
	var room_y: int = leaf.rect.position.y + (randi() % maxi(lh - room_h, 1))
	
	leaf.room = Rect2i(room_x, room_y, room_w, room_h)
	rooms.append(leaf.room)
	
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
	
	var center_a: Vector2i = _get_room_center(leaf.left)
	var center_b: Vector2i = _get_room_center(leaf.right)
	
	if randf() > 0.5:
		_carve_h_corridor(center_a.x, center_b.x, center_a.y)
		_carve_v_corridor(center_a.y, center_b.y, center_b.x)
	else:
		_carve_v_corridor(center_a.y, center_b.y, center_a.x)
		_carve_h_corridor(center_a.x, center_b.x, center_b.y)

func _place_shop_tile() -> void:
	# Place a shop tile in a random room (not the first or last room)
	if rooms.size() < 2:
		return
	
	# Choose a random room that's not the first or last
	var room_index: int = 1 + (randi() % maxi(rooms.size() - 2, 1))
	var room: Rect2i = rooms[room_index]
	
	# Place shop tile at a random position within the room
	var sx: int = room.position.x + (randi() % maxi(room.size.x, 1))
	var sy: int = room.position.y + (randi() % maxi(room.size.y, 1))
	map_data.set_tile(sx, sy, TileMapData.Tile.SHOP)

func _carve_h_corridor(x1: int, x2: int, y: int) -> void:
	var start_x: int = mini(x1, x2)
	var end_x: int = maxi(x1, x2)
	for x in range(start_x, end_x + 1):
		if map_data.get_tile(x, y) == TileMapData.Tile.WALL:
			map_data.set_tile(x, y, TileMapData.Tile.FLOOR)

func _carve_v_corridor(y1: int, y2: int, x: int) -> void:
	var start_y: int = mini(y1, y2)
	var end_y: int = maxi(y1, y2)
	for y in range(start_y, end_y + 1):
		if map_data.get_tile(x, y) == TileMapData.Tile.WALL:
			map_data.set_tile(x, y, TileMapData.Tile.FLOOR)
