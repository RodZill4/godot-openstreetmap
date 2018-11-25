extends Spatial

export(Mesh) var mesh
export(int, 1, 8) var subdivide = 4

var count = 0
var instances = []
var subdivisions = []

func _ready():
	var subdivision_length = osm.TILE_SIZE / subdivide
	instances.resize(subdivide*subdivide)
	subdivisions.resize(subdivide*subdivide)
	for x in range(subdivide):
		for y in range(subdivide):
			var multimesh_instance = MultiMeshInstance.new()
			var multimesh = MultiMesh.new()
			multimesh.set_mesh(mesh)
			#multimesh.set_aabb(Rect3(Vector3(-subdivision_length*0.5, 0, -subdivision_length*0.5), Vector3(subdivision_length, 100, subdivision_length)))
			multimesh_instance.set_multimesh(multimesh)
			multimesh_instance.set_translation(Vector3((x+0.5)*subdivision_length, 0, (y+0.5)*subdivision_length))
			multimesh_instance.lod_min_distance = 0
			multimesh_instance.lod_max_distance = 200
			add_child(multimesh_instance)
			subdivisions[x+y*subdivide] = multimesh_instance
			instances[x+y*subdivide] = []

func add(pos):
	var subdivision_length = osm.TILE_SIZE / subdivide
	var x = int(pos.x / subdivision_length)
	var y = int(pos.z / subdivision_length)
	instances[x+y*subdivide].append(pos-Vector3())
	count += 1

func update():
	var identity = Transform(Quat(Vector3(0, 1, 0), 0))
	var subdivision_length = osm.TILE_SIZE / subdivide
	for i in range(subdivide*subdivide):
		var instance_count = instances[i].size()
		var multimesh = subdivisions[i].get_multimesh()
		var center = subdivisions[i].get_translation()
		multimesh.set_instance_count(instance_count)
		for j in range(instance_count):
			multimesh.set_instance_transform(j, identity.translated(instances[i][j]-center).rotated(Vector3(0, 1, 0), j))
		instances[i] = []
	count = 0
