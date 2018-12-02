extends MeshInstance

export(Material) var material
export(float) var lane_width = 1.5
export(float) var border_width = 0
export(float) var road_height = 0.001

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func update_data(data):
	var generated_mesh = Mesh.new()
	var roads_vertices = PoolVector3Array()
	var roads_normals = PoolVector3Array()
	for road in data.roads:
		var lanes = road.width
		var points = road.points
		var normals = PoolVector2Array()
		var point_count = points.size()
		for j in range(point_count):
			normals.append(Vector2(0, 0))
		for j in range(point_count-1):
			var n = (points[j+1]-points[j]).rotated(0.5*PI).normalized()
			normals[j] += n 
			normals[j+1] += n 
		for j in range(point_count):
			var a = points[j]
			var n = normals[j].normalized()*(lane_width*lanes+border_width)
			if j == 0:
				roads_vertices.append(Vector3(a.x+n.x, road_height, a.y+n.y))
				roads_normals.append(Vector3(0, 1, 0))
			roads_vertices.append(Vector3(a.x+n.x, road_height, a.y+n.y))
			roads_normals.append(Vector3(0, 1, 0))
			roads_vertices.append(Vector3(a.x-n.x, road_height, a.y-n.y))
			roads_normals.append(Vector3(0, 1, 0))
			if j == point_count-1:
				roads_vertices.append(Vector3(a.x-n.x, road_height, a.y-n.y))
				roads_normals.append(Vector3(0, 1, 0))
	var surface = [ roads_vertices, roads_normals, null, null, null, null, null, null, null ]
	generated_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, surface)
	generated_mesh.surface_set_material(generated_mesh.get_surface_count()-1, material)
	call_deferred("on_updated", generated_mesh)

func on_updated(generated_mesh):
	mesh = generated_mesh
