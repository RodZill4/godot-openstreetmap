extends MultiMeshInstance3D

@export_enum("Trees", "Traffic lights", "Postboxes", "Fountains") var object_type: int = 0
@export var mesh : Mesh

const OBJECT_NAMES = [ "trees", "traffic_lights", "postboxes", "fountains" ]

func _ready():
	multimesh = MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D

func update_data(data):
	var positions = data[OBJECT_NAMES[object_type]]
	multimesh.instance_count = positions.size()
	for i in range(positions.size()):
		var p = positions[i]
		multimesh.set_instance_transform(i, Transform3D().translated(Vector3(p.x, 0, p.y)))

