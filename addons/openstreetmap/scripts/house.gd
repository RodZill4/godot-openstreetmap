tool
extends MeshInstance

export(int,"Flat","Convex","Slanted") var roof_shape = 0 setget set_roof_shape
export(PoolVector2Array) var polygon setget set_polygon
export(int,1,20) var height = 2 setget set_height
export(float,0,10,0.1) var level_height = 2.5 setget set_level_height
export(float,0.1,10,0.1) var window_width = 2.5 setget set_window_width
export(Material) var wall_material
export(float,0,85,1) var roof_angle = 20 setget set_roof_angle
export(Material) var roof_material

func set_roof_shape(s):
	roof_shape = s
	editor_update()

func set_polygon(p):
	polygon = p
	editor_update()

func set_height(h):
	height = h
	editor_update()

func set_level_height(h):
	level_height = h
	editor_update()

func set_window_width(w):
	window_width = w
	editor_update()

func set_roof_angle(a):
	roof_angle = a
	editor_update()

func editor_update():
	if Engine.is_editor_hint():
		if has_node("Polygon2D"):
			polygon = get_node("Polygon2D").get_polygon()
		force_update()

func force_update():
	var meshes = load("res://addons/openstreetmap/global/meshes.gd")
	mesh = ArrayMesh.new()
	var walls = meshes.Walls.new(false, true)
	walls.add(polygon, null, level_height*height, 0.5, height, 1/window_width)
	walls.add_to_mesh(mesh, wall_material)
	var roof
	if roof_shape == 1:
		roof = meshes.ConvexRoofs.new()
	else:
		roof = meshes.Roofs.new()
	roof.add(polygon, level_height*height, roof_angle)
	roof.add_to_mesh(mesh, roof_material)
