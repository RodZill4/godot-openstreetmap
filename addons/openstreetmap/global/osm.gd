extends Node

const ZOOM = 16
const TILE_SIZE = 256 * 156412.0 / (1 << ZOOM)

const TWM_ID      = 7938
const TWM_VERSION = 4

func _ready():
	print(TILE_SIZE)
	pass

func pos2tile(lon, lat):
	var n = 1 << ZOOM
	var x = n * (lon / 360.0 + 0.5)
	var a = lat * PI / 180.0
	var y = n * (1 - (log(tan(a) + 1.0/cos(a)) / PI)) * 0.5
	return Vector2(x, y)

func tile2pos(x, y):
	var n = 1 << ZOOM
	var lon_deg = x * 360.0 / n - 180.0
	var lat_rad = atan(sinh(PI * (1.0 - 2.0 * y / n)))
	var lat_deg = lat_rad * 180.0 / PI
	return Vector2(lon_deg, lat_deg)

func is_valid(f):
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

func gen_twm(in_file, out_file, x, y):
	var parser = XMLParser.new()
	parser.open(in_file)
	var nodes = { }
	var ways = { }
	var buildings = [ ]
	var houses = [ ]
	var grasslands = [ ]
	var water = [ ]
	var roads = [ ]
	var trees = [ ]
	var rocks = [ ]
	var post_boxes = [ ]
	var fountains = [ ]
	var stack = [ ]
	var count = 0
	var last_node
	var last_node2
	var rect = Rect2(Vector2(0, 0), Vector2(osm.TILE_SIZE, osm.TILE_SIZE))
	while parser.read() == 0:
		var pop_item = false
		var type = parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			if parser.is_empty():
				pop_item = true
			var name = parser.get_node_name()
			stack.append( { name = name } )
			# Operations that must be executed when entering an XML node
			if name == "node":
				var pos = pos2tile(float(parser.get_named_attribute_value("lon")), float(parser.get_named_attribute_value("lat")))
				pos -= Vector2(x, y)
				pos *= osm.TILE_SIZE
				var id = parser.get_named_attribute_value("id")
				if nodes.has(id):
					print("Duplicate node "+id)
				nodes[id] = pos
				stack.back().pos = pos
			elif name == "way":
				stack.back().id = parser.get_named_attribute_value("id")
				stack.back().nodes = [ ]
				stack.back().type = "none"
				last_node = null
				last_node2 = null
			elif name == "nd":
				var node = nodes[parser.get_named_attribute_value("ref")]
				if last_node == null || (node-last_node).length() > 2:
					if last_node2 != null && abs((last_node - last_node2).angle_to(node-last_node)) < 0.1:
						stack[stack.size()-2].nodes.pop_back()
					else:
						last_node2 = last_node
					last_node = node
					stack[stack.size()-2].nodes.append(node)
			elif name == "tag":
				var stack_size = stack.size()
				var k = parser.get_named_attribute_value("k")
				var v = parser.get_named_attribute_value("v")
				if stack[stack_size-2].has("pos"):
					var pos = stack[stack_size-2].pos
					if rect.has_point(pos):
						if k == "natural" && v == "tree":
							add_item(trees, pos, 0.05)
						elif k == "crossing" && v == "traffic_signals":
							add_item(rocks, pos, 0.05)
						elif k == "amenity":
							if v == "post_box":
								add_item(post_boxes, pos, 0.5)
							elif v == "fountain" || v == "drinking_water":
								add_item(fountains, pos, 0.5)
				if k == "building":
					stack[stack.size()-2].type = "building"
				elif k == "landuse" && v == "grass" || k == "natural" && v == "grassland":
					stack[stack.size()-2].type = "grassland"
				elif k == "natural" && v == "water" || k == "waterway" || k == "water":
					stack[stack.size()-2].type = "water"
				elif k == "highway":
					stack[stack.size()-2].type = "road"
				elif k == "lanes":
					stack[stack.size()-2].lanes = int(v)
				elif k == "building:levels":
					stack[stack.size()-2].height = int(v)
		elif type == XMLParser.NODE_ELEMENT_END:
			pop_item = true
		if pop_item:
			# Operations that must be executed when exiting an XML node
			if stack.back().name == "way":
				var way_nodes = stack.back().nodes
				if stack.back().type == "building":
					var building_nodes = geometry.fix_polygon(way_nodes)
					if rect.has_point(way_center(building_nodes)):
						var area = geometry.polygon_area(way_nodes)
						if area < 0:
							area = -area
						else:
							geometry.reverse_polygon(way_nodes)
						var height = 0
						if stack.back().has("height"):
							height = stack.back().height
						if int(height) < 1:
							height = floor(0.75*sqrt(sqrt(area)))
						if height > 0 && geometry.polygon_has_problems(building_nodes) == 0:
							var fixed_nodes
							for i in range(10):
								var retry = false
								fixed_nodes = [ ]
								for n in building_nodes:
									fixed_nodes.append(n+0.1*Vector2(randf(), randf()))
								var skeleton = geometry.create_straight_skeleton(building_nodes)
								for p in skeleton:
									if Geometry.triangulate_polygon(p).size() == 0:
										retry = true
								if !retry:
									break
							buildings.append({ height = height, polygon = fixed_nodes})
				elif stack.back().type == "grassland":
					var grassland_nodes = geometry.fix_polygon(way_nodes)
					if true || rect.has_point(way_center(grassland_nodes)):
						if geometry.polygon_has_problems(grassland_nodes) == 0:
							grasslands.append(grassland_nodes)
						else:
							print("grassland polygon has problems")
				elif stack.back().type == "water":
					var water_nodes = stack.back().nodes
					if water_nodes.front() == water_nodes.back():
						water_nodes = geometry.clamp_polygon(water_nodes, rect)
						if water_nodes.size() > 0:
							water.append(water_nodes)
				elif stack.back().type == "road":
					var road_nodes = way_nodes
					var visible = false
					for n in road_nodes:
						if rect.has_point(n):
							visible = true
							break
					if visible:
						var lanes = 1
						if stack.back().has("lanes"):
							lanes = stack.back().lanes
						roads.append( { nodes = road_nodes, lanes = lanes } )
			stack.pop_back()
	var out = File.new()
	out.open(out_file, File.WRITE)
	out.store_16(TWM_ID)
	out.store_8(TWM_VERSION)
	out.store_16(buildings.size())
	for b in buildings:
		out.store_8(b.height)
		out.store_16(b.polygon.size())
		for v in b.polygon:
			out.store_float(v.x)
			out.store_float(v.y)
	out.store_16(grasslands.size())
	for g in grasslands:
		out.store_16(g.size())
		for v in g:
			out.store_float(v.x)
			out.store_float(v.y)
	out.store_16(water.size())
	for w in water:
		out.store_16(w.size())
		for v in w:
			out.store_float(v.x)
			out.store_float(v.y)
	out.store_16(roads.size())
	for r in roads:
		out.store_8(r.lanes)
		out.store_16(r.nodes.size())
		for v in r.nodes:
			out.store_float(v.x)
			out.store_float(v.y)
	store_list(out, trees)
	store_list(out, rocks)
	store_list(out, post_boxes)
	store_list(out, fountains)
	out.close()

func way_center(points):
	var c = Vector2(0, 0)
	for p in points:
		c += p
	return c / points.size()

func add_item(list, item, min_dist):
	for i in list:
		if (i - item).length() < min_dist:
			return
	list.append(item)

func store_list(out, l):
	out.store_16(l.size())
	for t in l:
		out.store_float(t.x)
		out.store_float(t.y)
