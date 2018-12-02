extends MeshInstance

export(bool) var use_splatmap = true

func _ready():
	var size = osm.TILE_SIZE+0.1
	mesh.size = Vector2(size, size)
	transform = Transform(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1), Vector3(0.5*size, 0, 0.5*size))
	set_surface_material(0, get_surface_material(0).duplicate())

func set_ground_texture(t):
	if use_splatmap:
		var mat = get_surface_material(0)
		if mat != null:
			if mat is SpatialMaterial:
				mat.albedo_texture = t
			elif mat is ShaderMaterial:
				mat.set_shader_param("splatmap", t)