extends MeshInstance

export(float) var building_level_height = 6
export(Material) var building_wall_material
export(Material) var building_roof_material
export(float) var house_level_height = 2.5
export(float, 0, 85) var house_roof_angle = 20
export(Material) var house_wall_material
export(Material) var house_roof_material

func update_data(data):
	var generated_mesh = Mesh.new()
	var house_model = null #preload("res://addons/openstreetmap/house.tscn")
	var house_walls = meshes.Walls.new()
	var flat_roofs = meshes.Polygons.new()
	var house_roofs = meshes.Roofs.new()
	var house_convex_roofs = meshes.ConvexRoofs.new()
	var building_walls = meshes.Walls.new()
	var static_bodies = []
	#
	# Create buildings
	#
	for b in data.buildings:
		var height = b.height
		var polygon = b.points
		var point_count = polygon.size()
		var c = Vector2(0, 0)
		for p in polygon:
			c += p
		c /= point_count
		var hue = 10*(polygon[0].x+polygon[0].y)/osm.TILE_SIZE
		hue = 6*(hue - floor(hue))
		var color = hsv2rgb(hue, 0.1, 1)
		var roofs = null
		var flat_roof = true
		var is_convex = geometry.polygon_is_convex(polygon)
		if height < 4:
			if false:
				for j in range(point_count):
					polygon[j] -= c
				var house = house_model.instance()
				house.polygon = polygon
				house.height = height
				house.roof_angle = house_roof_angle
				house.force_update()
				house.set_translation(Vector3(c.x, 0, c.y))
				add_child(house)
				flat_roof = false
			else:
				var roof_type = house_roofs
				if is_convex:
					roof_type = house_convex_roofs
				if roof_type.add(polygon, house_level_height*height, house_roof_angle, color):
					house_walls.add(polygon, color, house_level_height*height, 0.5, height, 0.25)
					flat_roof = false
				else:
					height = max(1, int(height * 0.7))
		if flat_roof:
			flat_roofs.add(polygon, building_level_height*height)
			building_walls.add(polygon, color, building_level_height*height, 0.5, height, 0.25)
	building_walls.add_to_mesh(generated_mesh, building_wall_material)
	flat_roofs.add_to_mesh(generated_mesh, building_roof_material)
	house_walls.add_to_mesh(generated_mesh, house_wall_material)
	house_roofs.add_to_mesh(generated_mesh, house_roof_material)
	house_convex_roofs.add_to_mesh(generated_mesh, house_roof_material)
	call_deferred("on_updated", generated_mesh)

func on_updated(generated_mesh):
	mesh = generated_mesh

func hsv2rgb(h, s, v):
	var c = Color()
	c.h = h
	c.s = s
	c.v = v
	return c

func add_horizontal_triangles(mesh, vertices, colors, material):
	if vertices.size() > 0:
		var normals = PoolVector3Array()
		var uvs = PoolVector2Array()
		for v in vertices:
			normals.append(Vector3(0, 1, 0))
			uvs.append(Vector2(v.x, v.z))
		if colors != null: colors = PoolColorArray(colors)
		var surface = [ PoolVector3Array(vertices), normals, null, colors, uvs, null, null, null, null ]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
		mesh.surface_set_material(mesh.get_surface_count()-1, material)

func add_primitive(mesh, primitive, vertices, normals, colors, uvs, uv2s, material):
	if vertices.size() > 0:
		if vertices != null: vertices = PoolVector3Array(vertices)
		if normals != null: normals = PoolVector3Array(normals)
		if colors != null: colors = PoolColorArray(colors)
		if uvs != null: uvs = PoolVector2Array(uvs)
		if uv2s != null: uv2s = PoolVector2Array(uv2s)
		var surface = [ vertices, normals, null, colors, uvs, uv2s, null, null, null ]
		mesh.add_surface_from_arrays(primitive, surface)
		mesh.surface_set_material(mesh.get_surface_count()-1, material)
