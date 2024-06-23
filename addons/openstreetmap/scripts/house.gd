@tool
extends MeshInstance3D

@export_enum("Flat","Convex","Slanted") var roof_shape : int = 0 :
	set(s): set_roof_shape(s)
@export var polygon : PackedVector2Array :
	set(p): set_polygon(p)
@export_range(1,20) var height = 2 :
	set(h): set_height(h)
@export_range(0,10,0.1) var level_height : float = 2.5 :
	set(h): set_level_height(h)
@export_range(0.1,10,0.1) var window_width : float = 2.5 :
	set(w): set_window_width(w)
@export var wall_material : Material
@export_range(0,85,1) var roof_angle : float = 20 :
	set(a): set_roof_angle(a)
@export var roof_material : Material

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
