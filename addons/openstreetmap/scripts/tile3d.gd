extends Spatial

export(float) var building_level_height = 6
export(Material) var building_wall_material
export(Material) var building_roof_material
export(float) var house_level_height = 2.5
export(float, 0, 85) var house_roof_angle = 20
export(Material) var house_roof_material

var x
var y
var osm_x
var osm_y

onready var buildings = get_node("Buildings")
onready var doors = get_node("Doors")
onready var grounds = get_node("Grounds")
onready var trees = get_node("Trees")
onready var traffic_lights = get_node("TrafficLights")
onready var postboxes = get_node("PostBoxes")
onready var fountains = get_node("Fountains")
onready var child_nodes = [ buildings, grounds, doors, trees, traffic_lights, fountains, postboxes]

const WATER_HEIGHT  = 0.02
const ROAD_HEIGHT  = 0.04
const GRASS_HEIGHT = 0.06

const OSM_SIZE = 8

const SPLAT_GROUND = true
const SPLAT_SIZE   = 1024

const MULTIMESH_COUNT = 50000

func _ready():
	var ground = get_node("Ground")
	if SPLAT_GROUND:
		var material = ground.get_material_override().duplicate()
		material.set_shader_param("splatmap", get_node("Ground/RenderToTexture").get_render_target_texture())
		ground.set_material_override(material)
	else:
		ground.set_material_override(preload("res://addons/openstreetmap/materials/mat_simpleground.tres"))

func set_state(s):
	call_deferred("do_set_state", s)

func do_set_state(s):
	for c in get_node("State").get_children():
		if s == c.get_name():
			c.show()
		else:
			c.hide()

func halton(i, b):
	var r = 0
	var f = 1.0
	while i > 0:
		f = f/b
		r += f * (i % b)
		i /= b
	return r

func hsv2rgb(h, s, v):
	if s == 0:
		return Color(v, v, v)
	var i = floor(h)
	var f = h - i
	var p = v * (1-s)
	var q = v * (1-s*f)
	var t = v * (1-s*(1-f))
	if i == 0:
		return Color(v, t, p)
	elif i == 1:
		return Color(q, v, t)
	elif i == 2:
		return Color(p, v, t)
	elif i == 3:
		return Color(p, q, v)
	elif i == 4:
		return Color(t, p, v)
	else:
	    return Color(v, p, q)

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
	for c in child_nodes:
		c.hide()
	var twm_file_name = "user://tiles3d/twm/"+"tile_"+str(osm.ZOOM)+"_"+str(x)+"_"+str(y)+".twm"
	var osm_file_name = "user://tiles3d/osm/"+"tile_"+str(osm.ZOOM)+"_"+str(osm_x)+"_"+str(osm_y)+".osm"
	update_tile(twm_file_name, osm_file_name)

func update_tile(twm_file_name, osm_file_name):
	var dir = Directory.new()
	if !dir.file_exists(twm_file_name) && !osm.is_valid(osm_file_name):
			var pos1 = osm.tile2pos(osm_x, osm_y)
			var pos2 = osm.tile2pos(osm_x+OSM_SIZE, osm_y+OSM_SIZE)
			set_state("Downloading")
			http.download("http://overpass-api.de/api/map?bbox="+str(pos1.x)+","+str(pos2.y)+","+str(pos2.x)+","+str(pos1.y), osm_file_name, self, "update_tile", [twm_file_name, osm_file_name])
			return
	set_state("Waiting")
	background.run(self, "do_update_tile", {twm_file_name = twm_file_name, osm_file_name = osm_file_name})
	#do_update_tile( {twm_file_name = twm_file_name, osm_file_name = osm_file_name} )

func do_update_tile(data):
	load_twm(data.twm_file_name, data.osm_file_name)

func load_twm(twm_file_name, osm_file_name):
	var ground_painter
	if SPLAT_GROUND:
		get_node("Ground/RenderToTexture").set_rect(Rect2(0, 0, SPLAT_SIZE, SPLAT_SIZE))
		ground_painter = get_node("Ground/RenderToTexture/Draw")
		ground_painter.init()
		ground_painter.set_pos(SPLAT_SIZE*Vector2(0, 1))
		ground_painter.set_rot(0.5*PI)
		ground_painter.set_scale(SPLAT_SIZE/osm.TILE_SIZE*Vector2(1, 1))
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
	# Remove houses if any
	#
	for o in buildings.get_children():
		o.queue_free()
	var mesh_shadow = Mesh.new()
	var mesh_noshadow = Mesh.new()
	var flatroofs_vertices = []
	var flatroofs_colors = []
	var house_model = preload("res://addons/openstreetmap/house.tscn")
	var house_walls = meshes.Walls.new()
	var house_roofs = meshes.Roofs.new()
	var building_walls = meshes.Walls.new(false, true)
	#
	# Read and create buildings
	#
	var building_count = file.get_16()
	print(str(building_count)+" buildings")
	for i in range(building_count):
		var height = file.get_8()
		var point_count = file.get_16()
		var polygon = Vector2Array()
		var c = Vector2(0, 0)
		for j in range(point_count):
			var x = file.get_float()
			var y = file.get_float()
			var p = Vector2(x, y)
			c += p
			polygon.append(p)
		c /= point_count
		if SPLAT_GROUND:
			ground_painter.buildings.append(polygon)
		var hue = 10*(polygon[0].x+polygon[0].y)/osm.TILE_SIZE
		hue = 6*(hue - floor(hue))
		var color = hsv2rgb(hue, 0.1, 1)
		var roofs = null
		var flat_roofs = true
		if height < 90:
			if i % 8 == 0:
				for j in range(point_count):
					polygon[j] -= c
				var house = house_model.instance()
				house.polygon = polygon
				house.height = height
				house.roof_angle = house_roof_angle
				house.force_update()
				house.set_translation(Vector3(c.x, 0, c.y))
				buildings.add_child(house)
				flat_roofs = false
			else:
				if house_roofs.add(polygon, house_level_height*height, house_roof_angle, color):
					house_walls.add(polygon, color, house_level_height*height, 0.5, height, 0.25)
					flat_roofs = false
				else:
					height = max(1, int(height * 0.7))
		if flat_roofs:
			var indexes = Geometry.triangulate_polygon(polygon)
			for i in range(indexes.size()):
				var a = polygon[indexes[i]]
				flatroofs_vertices.append(Vector3(a.x, building_level_height*height, a.y))
				flatroofs_colors.append(color)
			building_walls.add(polygon, color, building_level_height*height, 0.5, height, 0.25)
	#
	# Read and create grasslands and water
	#
	var grasslands_vertices = []
	var water_vertices = []
	if SPLAT_GROUND:
		read_areas_to_splatmap(file, ground_painter.grass, "grass")
		read_areas_to_splatmap(file, ground_painter.water, "water")
	else:
		read_areas(file, grasslands_vertices, GRASS_HEIGHT, "grass")
		read_areas(file, water_vertices, WATER_HEIGHT, "water")
	#
	# Read and create roads
	#
	var roads_count = file.get_16()
	var roads_vertices = []
	var roads_normals = []
	for i in range(roads_count):
		var lanes = file.get_8()
		var line = Vector2Array()
		var point_count = file.get_16()
		for j in range(point_count):
			var x = file.get_float()
			var y = file.get_float()
			var point = Vector2(x, y)
			line.append(point)
		if SPLAT_GROUND:
			ground_painter.roads.append( { width = SPLAT_SIZE*lanes/128, points = line } )
		else:
			var normals = Vector2Array()
			for j in range(point_count):
				normals.append(Vector2(0, 0))
			for j in range(point_count-1):
				var n = (line[j+1]-line[j]).rotated(0.5*PI).normalized()
				normals[j] += n 
				normals[j+1] += n 
			for j in range(point_count):
				var a = line[j]
				var n = normals[j].normalized()*3*lanes
				if j == 0:
					roads_vertices.append(Vector3(a.x+n.x, ROAD_HEIGHT, a.y+n.y))
					roads_normals.append(Vector3(0, 1, 0))
				roads_vertices.append(Vector3(a.x+n.x, ROAD_HEIGHT, a.y+n.y))
				roads_normals.append(Vector3(0, 1, 0))
				roads_vertices.append(Vector3(a.x-n.x, ROAD_HEIGHT, a.y-n.y))
				roads_normals.append(Vector3(0, 1, 0))
				if j == point_count-1:
					roads_vertices.append(Vector3(a.x-n.x, ROAD_HEIGHT, a.y-n.y))
					roads_normals.append(Vector3(0, 1, 0))
	if SPLAT_GROUND:
		# Draw splatmap for roads, grass and water
		ground_painter.update()
		get_node("Ground/RenderToTexture").set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_ONCE)
	else:
		# Add geometry for roads, grass and water
		add_primitive(mesh_noshadow, Mesh.PRIMITIVE_TRIANGLE_STRIP, roads_vertices, roads_normals, null, null, null, preload("res://addons/openstreetmap/materials/mat_road.tres"))
		add_horizontal_triangles(mesh_noshadow, grasslands_vertices, null, preload("res://addons/openstreetmap/materials/mat_grass.tres"))
		add_horizontal_triangles(mesh_noshadow, water_vertices, null, preload("res://addons/openstreetmap/materials/mat_water.tres"))
	# Add geometry for buildings
	add_horizontal_triangles(mesh_noshadow, flatroofs_vertices, flatroofs_colors, building_roof_material)
	building_walls.add_to_mesh(mesh_shadow, building_wall_material)
	house_walls.add_to_mesh(mesh_shadow, building_wall_material)
	house_roofs.add_to_mesh(mesh_shadow, house_roof_material)
	# Load ans add trees, traffic_lights, postboxes and fountains
	load_objects(file, trees, "res://addons/openstreetmap/objects/tree.tscn", "tree")
	load_objects(file, traffic_lights, "res://addons/openstreetmap/objects/traffic_light.tscn", "traffic_light")
	load_objects(file, postboxes, "res://addons/openstreetmap/objects/post_box.tscn")
	load_objects(file, fountains, "res://addons/openstreetmap/objects/fountain.tscn")
	var grass = get_node("Grounds/Grass")
	var plants = get_node("Grounds/Plant")
	var stones = get_node("Grounds/Stones")
	var brown_grass = get_node("Grounds/BrownGrass")
	ground_painter.generate_image()
	for i in range(MULTIMESH_COUNT):
		var lx = halton(i+20, 5)*osm.TILE_SIZE
		var ly = halton(i+20, 3)*osm.TILE_SIZE
		var terrain_type = ground_painter.get_terrain_type(lx, ly)
		if terrain_type == ground_painter.TERRAIN_DIRT:
			if stones.count > brown_grass.count:
				brown_grass.add(Vector3(lx, 0, ly))
			else:
				stones.add(Vector3(lx, 0, ly))
		elif terrain_type == ground_painter.TERRAIN_GRASS:
			if 3*plants.count > grass.count:
				grass.add(Vector3(lx, 0, ly))
			else:
				plants.add(Vector3(lx, 0, ly))
	ground_painter.free_image()
	grass.update()
	plants.update()
	brown_grass.update()
	stones.update()
	set_state("")
	call_deferred("on_loaded", mesh_shadow, mesh_noshadow)

func fill_multimesh(array, parent, mesh):
	var multimesh_instance = MultiMeshInstance.new()
	parent.add_child(multimesh_instance)
	var identity = Transform(Quat(Vector3(0, 1, 0), 0))
	var multimesh = MultiMesh.new()
	multimesh.set_mesh(mesh)
	multimesh.set_instance_count(array.size())
	for i in range(array.size()):
		var transform = identity.translated(array[i]).rotated(Vector3(0, 1, 0), i)
		multimesh.set_instance_transform(i, transform)
	multimesh.set_aabb(AABB(Vector3(0, 0, 0), Vector3(osm.TILE_SIZE, 1, osm.TILE_SIZE)))
	multimesh_instance.set_multimesh(multimesh)

func read_areas(file, vertices, height, name):
	var count = file.get_16()
	#print(str(count)+" "+name+" polygons")
	for i in range(count):
		var polygon = Vector2Array()
		var point_count = file.get_16()
		for j in range(point_count):
			var x = file.get_float()
			var y = file.get_float()
			polygon.append(Vector2(x, y))
		var indexes = Geometry.triangulate_polygon(polygon)
		if indexes.size() == 0:
			#print("Failed to triangulate "+name+" polygon")
			continue
		for i in range(indexes.size()):
			var a = polygon[indexes[i]]
			vertices.append(Vector3(a.x, height, a.y))

func read_areas_to_splatmap(file, array, name):
	var count = file.get_16()
	#print(str(count)+" "+name+" polygons")
	for i in range(count):
		var polygon = Vector2Array()
		var point_count = file.get_16()
		for j in range(point_count):
			var x = file.get_float()
			var y = file.get_float()
			polygon.append(Vector2(x, y))
		if polygon.size() > 2: array.append(polygon)

func on_loaded(mesh_shadow, mesh_noshadow):
	buildings.set_mesh(mesh_shadow)
	grounds.set_mesh(mesh_noshadow)
	for c in child_nodes:
		c.show()

func load_objects(file, parent, model_path, name = null):
	var object_count = file.get_16()
	for o in parent.get_children():
		o.queue_free()
	var object_model = load(model_path)
	for i in range(object_count):
		var object = object_model.instance()
		var ox = file.get_float()
		var oy = file.get_float()
		parent.add_child(object)
		object.set_translation(Vector3(ox, 0, oy))
		if name != null: object.set_name(name+"_"+str(x)+"_"+str(y)+"_"+str(i))
	parent.show()

func add_horizontal_triangles(mesh, vertices, colors, material):
	if vertices.size() > 0:
		var normals = Vector3Array()
		var uvs = Vector2Array()
		for v in vertices:
			normals.append(Vector3(0, 1, 0))
			uvs.append(Vector2(v.x, v.z))
		if colors != null: colors = ColorArray(colors)
		var surface = [ Vector3Array(vertices), normals, null, colors, uvs, null, null, null, null ]
		mesh.add_surface(Mesh.PRIMITIVE_TRIANGLES, surface)
		mesh.surface_set_material(mesh.get_surface_count()-1, material)

func add_primitive(mesh, primitive, vertices, normals, colors, uvs, uv2s, material):
	if vertices.size() > 0:
		if vertices != null: vertices = Vector3Array(vertices)
		if normals != null: normals = Vector3Array(normals)
		if colors != null: colors = ColorArray(colors)
		if uvs != null: uvs = Vector2Array(uvs)
		if uv2s != null: uv2s = Vector2Array(uv2s)
		var surface = [ vertices, normals, null, colors, uvs, uv2s, null, null, null ]
		mesh.add_surface(primitive, surface)
		mesh.surface_set_material(mesh.get_surface_count()-1, material)

