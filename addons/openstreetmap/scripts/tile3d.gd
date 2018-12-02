extends Spatial

var x
var y
var osm_x
var osm_y

var data = {}

var render_to_texture

var trees_positions = []

const WATER_HEIGHT  = 0.02
const ROAD_HEIGHT  = 0.04
const GRASS_HEIGHT = 0.06

const OSM_SIZE = 1

const SPLAT_GROUND = true
const SPLAT_SIZE   = 512

const MULTIMESH_COUNT = 0

func set_state(s):
	call_deferred("do_set_state", s)

func do_set_state(s):
	for c in get_node("State").get_children():
		if s == c.get_name():
			c.show()
		else:
			c.hide()

func set_tile(_x, _y):
	if x == _x && y == _y:
		return
	x = _x
	y = _y
	osm_x = int(x/OSM_SIZE)*OSM_SIZE
	osm_y = int(y/OSM_SIZE)*OSM_SIZE
	var rp = get_parent().reference_position
	set_translation(osm.TILE_SIZE*Vector3(x-rp.x, 0, y-rp.y))
	set_name("tile_3d_"+str(x)+"_"+str(y))
	var twm_file_name = "user://tiles3d/twm/"+"tile_"+str(osm.ZOOM)+"_"+str(x)+"_"+str(y)+".twm"
	var osm_file_name = "user://tiles3d/osm/"+"tile_"+str(osm.ZOOM)+"_"+str(osm_x)+"_"+str(osm_y)+".osm"
	update_tile(twm_file_name, osm_file_name)

func update_tile(twm_file_name, osm_file_name):
	var dir = Directory.new()
	if !dir.file_exists(twm_file_name) && !osm.is_valid(osm_file_name):
		var pos1 = osm.tile2pos(osm_x, osm_y)
		var pos2 = osm.tile2pos(osm_x+OSM_SIZE, osm_y+OSM_SIZE)
		set_state("Downloading")
		http.download("http://api.openstreetmap.org/api/0.6/map?bbox="+str(pos1.x)+","+str(pos2.y)+","+str(pos2.x)+","+str(pos1.y), osm_file_name, self, "update_tile", [twm_file_name, osm_file_name])
		return
	set_state("Waiting")
	#background.run(self, "do_update_tile", {twm_file_name = twm_file_name, osm_file_name = osm_file_name})
	do_update_tile( {twm_file_name = twm_file_name, osm_file_name = osm_file_name} )

func do_update_tile(data):
	load_twm(data.twm_file_name, data.osm_file_name)

func load_twm(twm_file_name, osm_file_name):
	data = {}
	var ground_painter
	var file = File.new()
	var ok = false
	while true:
		file.open(twm_file_name, File.READ)
		if file.is_open():
			var id = file.get_16()
			var version = file.get_8()
			if id == osm.TWM_ID && version == osm.TWM_VERSION:
				break
			file.close()
		set_state("Converting")
		osm.gen_twm(osm_file_name, twm_file_name, x, y)
	set_state("Loading")
	#
	# Read buildings
	#
	data.buildings = []
	var building_count = file.get_16()
	for i in range(building_count):
		var height = file.get_8()
		var point_count = file.get_16()
		var polygon = PoolVector2Array()
		var c = Vector2(0, 0)
		for j in range(point_count):
			var x = file.get_float()
			var y = file.get_float()
			var p = Vector2(x, y)
			polygon.append(p)
		data.buildings.append({ height=height, points=polygon })
	#
	# Read and create grasslands and water
	#
	for area in [ "grass", "water" ]:
		data[area] = []
		var count = file.get_16()
		for i in range(count):
			var polygon = PoolVector2Array()
			var point_count = file.get_16()
			for j in range(point_count):
				var x = file.get_float()
				var y = file.get_float()
				polygon.append(Vector2(x, y))
			if polygon.size() > 2:
				data[area].append(polygon)
	#
	# Read and create roads
	#
	data.roads = []
	var roads_count = file.get_16()
	var roads_vertices = []
	var roads_normals = []
	for i in range(roads_count):
		var lanes = file.get_8()
		var line = PoolVector2Array()
		var point_count = file.get_16()
		for j in range(point_count):
			var x = file.get_float()
			var y = file.get_float()
			var point = Vector2(x, y)
			line.append(point)
		data.roads.append( { width = SPLAT_SIZE*lanes/128, points = line } )
	#
	# Read and create trees, traffic_lights, postboxes and fountains
	#
	for object_type in [ "trees", "traffic_lights", "postboxes", "fountains" ]:
		var object_count = file.get_16()
		var positions_list = PoolVector2Array()
		for i in range(object_count):
			var ox = file.get_float()
			var oy = file.get_float()
			positions_list.append(Vector2(ox, oy))
		data[object_type] = positions_list
	for c in get_children():
		if c.has_method("update_data"):
			c.update_data(data)
	get_parent().generate_ground_texture(self)
	set_state("Ready")

func set_ground_texture(t):
	for c in get_children():
		if c.has_method("set_ground_texture"):
			c.set_ground_texture(t)

func set_center(p):
	for c in get_children():
		if c.has_method("set_center"):
			c.set_center(p)

func fill_multimesh(array, parent, mesh):
	var multimesh_instance = MultiMeshInstance.new()
	parent.add_child(multimesh_instance)
	var identity = Transform(Quat(Vector3(0, 1, 0), 0))
	var multimesh = MultiMesh.new()
	multimesh.set_mesh(mesh)
	multimesh.set_instance_count(array.size())
	for i in range(array.size()):
		var instance_transform = identity.translated(array[i]).rotated(Vector3(0, 1, 0), i)
		multimesh.set_instance_transform(i, instance_transform)
	multimesh.set_aabb(AABB(Vector3(0, 0, 0), Vector3(osm.TILE_SIZE, 1, osm.TILE_SIZE)))
	multimesh_instance.set_multimesh(multimesh)

func _on_Viewport_tree_exiting():
	print("Viewport exits tree")
