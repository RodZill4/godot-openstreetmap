extends Spatial

export(float) var building_level_height = 2.5
export(Material) var building_wall_material
export(Material) var building_roof_material
export(float, 0, 85) var house_roof_angle = 20
export(Material) var house_roof_material

var x
var y
var osm_x
var osm_y

onready var buildings = get_node("Buildings")
onready var doors = get_node("Doors")
onready var windows = get_node("Windows")
onready var grounds = get_node("Grounds")
onready var trees = get_node("Trees")
onready var traffic_lights = get_node("TrafficLights")
onready var postboxes = get_node("PostBoxes")
onready var fountains = get_node("Fountains")

const WATER_HEIGHT  = 0.02
const ROAD_HEIGHT  = 0.04
const GRASS_HEIGHT = 0.06

const OSM_SIZE = 8

const SPLAT_GROUND = true
const SPLAT_SIZE   = 1024

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
	buildings.hide()
	grounds.hide()
	doors.hide()
	windows.hide()
	trees.hide()
	traffic_lights.hide()
	fountains.hide()
	postboxes.hide()
	var twm_file_name = "user://tiles3d/twm/"+"tile_"+str(osm.ZOOM)+"_"+str(x)+"_"+str(y)+".twm"
	var osm_file_name = "user://tiles3d/osm/"+"tile_"+str(osm.ZOOM)+"_"+str(osm_x)+"_"+str(osm_y)+".osm"
	update_tile(twm_file_name, osm_file_name)

func is_valid_osm(f):
	var dir = Directory.new()
	if !dir.file_exists(f):
		return false
	var parser = XMLParser.new()
	parser.open(f)
	while parser.read() == 0:
		var type = parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			var name = parser.get_node_name()
			if name == "html":
				break
			elif name == "osm":
				return true
	print("Incorrect OSM file "+f)
	dir.remove(f)
	return false

func update_tile(twm_file_name, osm_file_name):
	var dir = Directory.new()
	if !dir.file_exists(twm_file_name) && !is_valid_osm(osm_file_name):
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
	while !ok:
		file.open(twm_file_name, File.READ)
		if !file.is_open():
			set_state("Converting")
			osm.gen_twm(osm_file_name, twm_file_name, x, y)
		else:
			var id = file.get_16()
			var version = file.get_8()
			if id != osm.TWM_ID || version != osm.TWM_VERSION:
				file.close()
				set_state("Converting")
				osm.gen_twm(osm_file_name, twm_file_name, x, y)
			else:
				ok = true
	set_state("Loading")
	var mesh_buildings = Mesh.new()
	var mesh_grounds = Mesh.new()
	var flatroofs_vertices = []
	var flatroofs_colors = []
	var roof_angle = house_roof_angle*PI/180
	var roof_texture_stretch = 1/cos(roof_angle)
	var roofs_vertices = []
	var roofs_colors = []
	var roofs_normals = []
	var roofs_uvs = []
	var walls_vertices = []
	var walls_colors = []
	var walls_normals = []
	var walls_uvs = []
	var walls_uv2s = []
	var building_count = file.get_16()
	var windows_array = []
	for i in range(building_count):
		var polygon = Vector2Array()
		var height = file.get_8()
		var point_count = file.get_16()
		for j in range(point_count):
			var x = file.get_float()
			var y = file.get_float()
			polygon.append(Vector2(x, y)+0.1*Vector2(randf(), randf()))
		var hue = 10*(polygon[0].x+polygon[0].y)/osm.TILE_SIZE
		hue = 6*(hue - floor(hue))
		var color = hsv2rgb(hue, 0.1, 1)
		var roofs = null
		if height < 4: roofs = geometry.create_straight_skeleton(polygon)
		var roof_indexes = [ ]
		var flat_roofs = (roofs == null)
		if !flat_roofs:
			for r in roofs:
				var indexes = Geometry.triangulate_polygon(r)
				if indexes.size() == 0:
					flat_roofs = true
					break
				roof_indexes.append(indexes)
		if flat_roofs:
			var indexes = Geometry.triangulate_polygon(polygon)
			for i in range(indexes.size()):
				var a = polygon[indexes[i]]
				flatroofs_vertices.append(Vector3(a.x, building_level_height*height, a.y))
				flatroofs_colors.append(color)
		else:
			for r in range(roofs.size()):
				var roof = roofs[r]
				var indexes = roof_indexes[r]
				var center = roof[0]
				var u_axis = (roof[1] - roof[0]).normalized()
				var v_axis = u_axis.rotated(0.5*PI)
				var normal = Vector3(0, 1, 0).rotated(Vector3(u_axis.x, 0, u_axis.y), -roof_angle)
				for i in range(indexes.size()):
					var a = roof[indexes[i]]
					var u = (a - center).dot(u_axis)
					var v = (a - center).dot(v_axis)
					roofs_vertices.append(Vector3(a.x, building_level_height*height+tan(roof_angle)*v, a.y))
					roofs_normals.append(normal)
					roofs_uvs.append(Vector2(u, -v*roof_texture_stretch))
					roofs_colors.append(color)
		generate_walls(polygon, color, building_level_height*height, 0.5, height, 0.25, walls_vertices, walls_colors, walls_normals, walls_uvs, walls_uv2s)
	var grasslands_vertices = []
	var water_vertices = []
	if SPLAT_GROUND:
		read_areas_to_rtt(file, ground_painter.grass, "grass")
		read_areas_to_rtt(file, ground_painter.water, "water")
	else:
		read_areas(file, grasslands_vertices, GRASS_HEIGHT, "grass")
		read_areas(file, water_vertices, WATER_HEIGHT, "water")
	var roads_vertices = []
	var roads_normals = []
	var roads_count = file.get_16()
	for i in range(roads_count):
		var lanes = file.get_8()
		var line = Vector2Array()
		var normals = Vector2Array()
		var point_count = file.get_16()
		for j in range(point_count):
			var x = file.get_float()
			var y = file.get_float()
			var point = Vector2(x, y)
			line.append(point)
		if SPLAT_GROUND:
			ground_painter.roads.append( { width = SPLAT_SIZE*lanes/128, points = line } )
		else:
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
		ground_painter.update()
		get_node("Ground/RenderToTexture").set_render_target_update_mode(Viewport.RENDER_TARGET_UPDATE_ONCE)
	else:
		add_primitive(mesh_grounds, Mesh.PRIMITIVE_TRIANGLE_STRIP, roads_vertices, roads_normals, null, null, null, preload("res://addons/openstreetmap/materials/mat_road.tres"))
		add_horizontal_triangles(mesh_grounds, grasslands_vertices, null, preload("res://addons/openstreetmap/materials/mat_grass.tres"))
		add_horizontal_triangles(mesh_grounds, water_vertices, null, preload("res://addons/openstreetmap/materials/mat_water.tres"))
	add_horizontal_triangles(mesh_grounds, flatroofs_vertices, flatroofs_colors, building_roof_material)
	add_primitive(mesh_buildings, Mesh.PRIMITIVE_TRIANGLES, roofs_vertices, roofs_normals, roofs_colors, roofs_uvs, null, house_roof_material)
	add_primitive(mesh_buildings, Mesh.PRIMITIVE_TRIANGLE_STRIP, walls_vertices, walls_normals, walls_colors, walls_uvs, walls_uv2s, building_wall_material)
	load_objects(file, trees, "res://addons/openstreetmap/objects/tree.tscn", "tree")
	load_objects(file, traffic_lights, "res://addons/openstreetmap/objects/traffic_light.tscn", "traffic_light")
	load_objects(file, postboxes, "res://addons/openstreetmap/objects/post_box.tscn")
	load_objects(file, fountains, "res://addons/openstreetmap/objects/fountain.tscn")
	set_state("")
	call_deferred("on_loaded", mesh_buildings, mesh_grounds)

func generate_walls(polygon, color, height, texture_width, texture_height, texture2_width, vertices, colors, normals, uvs, uv2s = null):
	polygon.append(polygon[0])
	var p0 = polygon[0]
	vertices.append(Vector3(p0.x, height, p0.y))
	colors.append(color)
	normals.append(Vector3(0, 0, 0))
	uvs.append(Vector2(0, 0))
	if uv2s != null: uv2s.append(Vector2(0, 0))
	var u = 0
	var u2 = 0
	for i in range(polygon.size()-1):
		var p1 = polygon[i]
		var p2 = polygon[i+1]
		var n = Vector3(p2.x-p1.x, 0, p2.y-p1.y).cross(Vector3(0, 1, 0)).normalized()
		vertices.append(Vector3(p1.x, height, p1.y))
		colors.append(color)
		normals.append(n)
		uvs.append(Vector2(u, 0))
		if uv2s != null: uv2s.append(Vector2(u2, 0))
		vertices.append(Vector3(p1.x, 0, p1.y))
		colors.append(color)
		normals.append(n)
		uvs.append(Vector2(u, texture_height))
		if uv2s != null: uv2s.append(Vector2(u2, texture_height))
		u += (p2-p1).length() * texture_width
		u2 += floor((p2-p1).length() * texture2_width)
		vertices.append(Vector3(p2.x, height, p2.y))
		colors.append(color)
		normals.append(n)
		uvs.append(Vector2(u, 0))
		if uv2s != null: uv2s.append(Vector2(u2, 0))
		vertices.append(Vector3(p2.x, 0, p2.y))
		colors.append(color)
		normals.append(n)
		uvs.append(Vector2(u, texture_height))
		if uv2s != null: uv2s.append(Vector2(u2, texture_height))
		var v = p2-p1
		var l = v.length()
	vertices.append(Vector3(p0.x, 0, p0.y))
	colors.append(color)
	normals.append(Vector3(0, 0, 0))
	uvs.append(Vector2(0, 0))
	if uv2s != null: uv2s.append(Vector2(0, 0))

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

func read_areas_to_rtt(file, array, name):
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

func on_loaded(mesh_buildings, mesh_grounds):
	buildings.set_mesh(mesh_buildings)
	grounds.set_mesh(mesh_grounds)
	buildings.show()
	grounds.show()
	windows.show()
	trees.show()
	traffic_lights.show()
	postboxes.show()
	fountains.show()

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

