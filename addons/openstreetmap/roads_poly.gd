extends MeshInstance3D

@export var material : Material
@export var lane_width : float = 1.5
@export var border_width : float = 0
@export var road_height : float = 0.001

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func update_data(data):
	var generated_mesh = ArrayMesh.new()
	var roads_vertices = PackedVector3Array()
	var roads_normals = PackedVector3Array()
	for road in data.roads:
		var lanes = road.width
		var points = road.points
		var normals = PackedVector2Array()
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
	print(surface)
	generated_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, surface)
	generated_mesh.surface_set_material(generated_mesh.get_surface_count()-1, material)
	call_deferred("on_updated", generated_mesh)

func on_updated(generated_mesh):
	mesh = generated_mesh
