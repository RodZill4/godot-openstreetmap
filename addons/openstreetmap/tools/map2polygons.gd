tool
extends Node2D

export(String) var mapfile = null setget set_mapfile

func _ready():
	pass

func set_mapfile(n):
	for c in get_children():
		remove_child(c)
	mapfile = n
	var file = File.new()
	file.open(n, File.READ)
	var id = file.get_16()
	var version = file.get_8()
	var building_count = file.get_16()
	var windows_array = []
	for i in range(building_count):
		var polygon = Vector2Array()
		var height = file.get_8()
		var point_count = file.get_16()
		for j in range(point_count):
			var x = file.get_float()
			var y = file.get_float()
			polygon.append(100*Vector2(x, y)+0.1*Vector2(randf()-0.5, randf()-0.5))
		var o = preload("res://addons/openstreetmap/tools/skeleton_test.gd").new()
		o.set_polygon(polygon)
		add_child(o)
		o.set_owner(self)
	file.close()
