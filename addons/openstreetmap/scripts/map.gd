extends Spatial

export(String) var tile_model = "res://addons/openstreetmap/tile3d.tscn"
export(int,0,3) var size = 1

onready var tile_class = load(tile_model)
var reference_position = Vector2(0, 0)
var x = null
var y = null

func _ready():
	var dir = Directory.new()
	for d in [ "user://tiles3d", "user://tiles3d/osm", "user://tiles3d/twm" ]:
		if !dir.dir_exists(d):
			dir.make_dir(d)

func tile_distance(t):
	return sqrt(t.x-x)*(t.x-x)+(t.y-y)*(t.y-y)

func tile_order(t1, t2):
	return tile_distance(t1) < tile_distance(t2)

func set_center(p):
	var map_pos = reference_position + p/osm.TILE_SIZE
	var _x = int(map_pos.x)
	var _y = int(map_pos.y)
	if x == _x && y == _y:
		return
	x = _x
	y = _y
	http.cancel()
	for t in get_children():
		t.hide()
	var needed_tiles = []
	for _x in range(2*size+1):
		for _y in range(2*size+1):
			var t = { x=int(x+_x-size), y=int(y+_y-size) }
			var name = "tile_3d_"+str(t.x)+"_"+str(t.y)
			if has_node(name):
				get_node(name).show()
			else:
				needed_tiles.append(t)
	var free_tiles = []
	for t in get_children():
		if !t.is_visible():
			free_tiles.append(t)
	needed_tiles.sort_custom(self, "tile_order")
	for t in needed_tiles:
		var tile
		if free_tiles.empty():
			tile = tile_class.instance()
			add_child(tile)
		else:
			tile = free_tiles.back()
			free_tiles.pop_back()
		tile.set_tile(t.x, t.y)
		tile.show()
