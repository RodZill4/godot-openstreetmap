extends MeshInstance

export(float) var building_height = 1.0
export(Material) var building_wall_material
export(Material) var building_roof_material

func update_data(data):
	var generated_mesh = Mesh.new()
	var flat_roofs = meshes.Polygons.new()
	var building_walls = meshes.Walls.new(false, false)
	#
	# Create buildings
	#
	for b in data.buildings:
		var height = b.height
		var polygon = b.points
		flat_roofs.add(polygon, building_height)
		building_walls.add(polygon, null, building_height, 0.5, 0, 0.25)
	building_walls.add_to_mesh(generated_mesh, building_wall_material)
	flat_roofs.add_to_mesh(generated_mesh, building_roof_material)
	call_deferred("on_updated", generated_mesh)

func on_updated(generated_mesh):
	mesh = generated_mesh
	