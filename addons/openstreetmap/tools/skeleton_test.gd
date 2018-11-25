tool
extends Polygon2D

export(bool) var show_polygons = true setget set_show_polygons

func _ready():
	pass

func _draw():
	var geometry = preload("res://addons/openstreetmap/global/geometry.gd")
	var skeleton = geometry.create_straight_skeleton(get_polygon(), self)
	if show_polygons:
		for p in skeleton: draw_colored_polygon(p, Color(0.7*randf(), 0.7*randf(), 0.7*randf()))
		for p in skeleton:
			var c = Color(randf(), randf(), randf(), 1)
			for i in range(p.size()):
				var i2 = i-1 if (i>0) else 0
				draw_line(p[i], p[i2], c, 5)
				draw_line(p[i], p[i]+50*Vector2(1, 0).rotated(i*0.2), c, 5)

func set_show_polygons(b):
	show_polygons = b
	update()