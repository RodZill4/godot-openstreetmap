extends Node2D

var roads = []
var grass = []
var water = []

func _ready():
	pass

func init():
	roads = []
	grass = []
	water = []

func _draw():
	for w in water:
		draw_colored_polygon(w, Color(0, 0, 1))
	for g in grass:
		draw_colored_polygon(g, Color(0, 1, 0))
	for r in roads:
		for i in range(r.points.size()-1):
			draw_line(r.points[i], r.points[i+1], Color(1, 0, 0), r.width)