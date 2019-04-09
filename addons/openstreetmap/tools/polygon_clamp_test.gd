tool
extends Polygon2D

export(bool) var show_polygons = true setget set_show_polygons

func _ready():
	pass

func is_inside_edge(p, e):
	return e.a*p.x+e.b*p.y+e.c >= 0

func intersect_line_with_edge(p1, p2, e):
	var r1 = e.a*p1.x+e.b*p1.y+e.c
	var r2 = e.a*p2.x+e.b*p2.y+e.c
	return (r2*p1-r1*p2)/(r2-r1)

func _draw():
	var geometry = preload("res://addons/openstreetmap/global/geometry.gd")
	var rect_node = get_node("rect")
	var rect = rect_node.get_shape().get_extents()
	rect = rect_node.get_transform().xform(Rect2(-rect, 2*rect))
	var output = geometry.clamp_polygon(get_polygon(), rect)
	if output != null:
		for p in output:
			draw_colored_polygon(p, Color(1, 0, 0))
			var s = p.size()
			for i in range(p.size()):
				draw_circle(p[i], 3, Color(0, 1, 0))
				draw_line(p[i], p[(i+1)%s], Color(0, 1, 0), 3)

func set_show_polygons(b):
	show_polygons = b
	update()