class_name TileMapData

enum Tile {
	WALL,
	FLOOR,
	DOOR,
	STAIRS_DOWN,
	STAIRS_UP,
	SHOP,
	SECRET_WALL,  # Looks like wall but can be opened with key
	SECRET_ROOM,  # Secret room floor
}

var width: int
var height: int
var grid: Array  # Array of Arrays of int (Tile enum)

func _init(w: int = 60, h: int = 60) -> void:
	width = w
	height = h
	grid = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(Tile.WALL)
		grid.append(row)

func get_tile(x: int, y: int) -> int:
	if x < 0 or x >= width or y < 0 or y >= height:
		return Tile.WALL
	return grid[y][x]

func set_tile(x: int, y: int, tile: int) -> void:
	if x >= 0 and x < width and y >= 0 and y < height:
		grid[y][x] = tile

func is_walkable(x: int, y: int) -> bool:
	var t := get_tile(x, y)
	return t == Tile.FLOOR or t == Tile.DOOR or t == Tile.STAIRS_DOWN or t == Tile.STAIRS_UP or t == Tile.SHOP or t == Tile.SECRET_ROOM

func get_random_floor_tile() -> Vector2i:
	var floor_tiles: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			if grid[y][x] == Tile.FLOOR:
				floor_tiles.append(Vector2i(x, y))
	if floor_tiles.is_empty():
		return Vector2i(width / 2, height / 2)
	return floor_tiles[randi() % floor_tiles.size()]
