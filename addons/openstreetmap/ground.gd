extends MeshInstance3D

@export var use_splatmap : bool = true

func _ready():
	var size = osm.TILE_SIZE+0.1
	mesh.size = Vector2(size, size)
	transform = Transform3D(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1), Vector3(0.5*size, 0, 0.5*size))
	set_surface_override_material(0, get_surface_override_material(0))

func set_ground_texture(t):
	if use_splatmap:
		var mat = get_surface_override_material(0)
		if mat != null:
			if mat is StandardMaterial3D:
				mat.albedo_texture = t
			elif mat is ShaderMaterial:
				mat.set_shader_parameter("splatmap", t)
