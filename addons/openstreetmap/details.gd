extends Particles

export(Mesh) var mesh
export(float) var spacing = 1.0
export(Color) var condition
export(Color) var condition_mask

func _ready():
	draw_pass_1 = mesh
	process_material = process_material.duplicate()
	visibility_aabb.position = Vector3(0, 0, 0)
	visibility_aabb.size     = Vector3(osm.TILE_SIZE, 2.0, osm.TILE_SIZE)
	process_material.set_shader_param("tile_size", osm.TILE_SIZE)
	process_material.set_shader_param("spacing", spacing)
	var rows = floor(osm.TILE_SIZE/spacing)
	process_material.set_shader_param("rows", rows)
	process_material.set_shader_param("condition", condition)
	process_material.set_shader_param("condition_mask", condition)
	amount = rows*rows

func set_ground_texture(t):
	process_material.set_shader_param("splatmap", t)