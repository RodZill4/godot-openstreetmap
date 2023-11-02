extends Node3D

@export var tile_model: String = "res://addons/openstreetmap/tile3d.tscn"
@export_range(0,4) var size : int = 1
@export var map_objects: Array = []

@onready var tile_class = load(tile_model)
var reference_position = Vector2(0, 0)
var x = null
var y = null
var tiles = []

func _ready():
	for d in [ "user://tiles3d", "user://tiles3d/osm", "user://tiles3d/twm" ]:
		if !DirAccess.dir_exists_absolute(d):
			DirAccess.make_dir_absolute(d)

func tile_distance(t):
	return sqrt(t.x-x)*(t.x-x)+(t.y-y)*(t.y-y)

func tile_order(t1, t2):
	return tile_distance(t1) < tile_distance(t2)

func set_center(p):
	#print("Setting center to "+str(p))
	var map_pos = reference_position + p/osm.TILE_SIZE
	var _x = int(map_pos.x)
	var _y = int(map_pos.y)
	if x != _x or y != _y:
		x = _x
		y = _y
		http.cancel()
		for t in tiles:
			t.hide()
		var needed_tiles = []
		for __x in range(2*size+1):
			for __y in range(2*size+1):
				var t = { x=int(x+__x-size), y=int(y+__y-size) }
				var name = "tile_3d_"+str(t.x)+"_"+str(t.y)
				if has_node(name):
					get_node(name).show()
				else:
					needed_tiles.append(t)
		var free_tiles = []
		for t in tiles:
			if !t.is_visible():
				free_tiles.append(t)
		needed_tiles.sort_custom(tile_order)
		for t in needed_tiles:
			var tile
			if free_tiles.is_empty():
				tile = tile_class.instantiate()
				add_child(tile)
				tiles.append(tile)
				for o in map_objects:
					tile.add_child(o.instantiate())
			else:
				tile = free_tiles.back()
				free_tiles.pop_back()
			tile.set_tile(t.x, t.y)
			tile.show()
	for t in tiles:
		t.set_center(p-Vector2(t.position.x, t.position.z))

var ground_texture_queue = []

func generate_ground_texture(o):
	ground_texture_queue.append(o)
	if ground_texture_queue.size() == 1:
		while !ground_texture_queue.is_empty():
			var object = ground_texture_queue.front()
			$GroundTextureGenerator.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			$GroundTextureGenerator/DrawGround.data = object.data
			await get_tree().process_frame # await get_tree().idle_frame
			await get_tree().process_frame
			$GroundTextureGenerator.render_target_update_mode = SubViewport.UPDATE_DISABLED
			var viewport_texture = $GroundTextureGenerator.get_texture()
			var target_texture = ImageTexture.new()
			target_texture.create_from_image(viewport_texture.get_image())
			# target_texture.flags = Texture.FLAG_MIPMAPS | Texture.FLAG_FILTER
			object.set_ground_texture(target_texture)
			ground_texture_queue.pop_front()
