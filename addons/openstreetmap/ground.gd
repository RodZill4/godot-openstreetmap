extends MeshInstance

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	var size = osm.TILE_SIZE
	transform = Transform(Vector3(size, 0, 0), Vector3(0, 0, size), Vector3(0, size, 0), Vector3(0.5*size, 0, 0.5*size))
	set_surface_material(0, get_surface_material(0).duplicate())

func set_ground_texture(t):
	var mat = get_surface_material(0)
	if mat != null:
		if mat is SpatialMaterial:
			mat.albedo_texture = t
		elif mat is ShaderMaterial:
			mat.set_shader_param("splatmap", t)