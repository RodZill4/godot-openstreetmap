tool
extends Node2D

var data = null setget set_data

func _ready():
	update()

func set_data(d):
	data = d
	update()

func _draw():
	var empty_vec2_array = PoolVector2Array()
	var viewport_size = get_parent().size
	scale = Vector2(viewport_size.x/osm.TILE_SIZE, viewport_size.y/osm.TILE_SIZE)
	draw_rect(Rect2(0, 0, osm.TILE_SIZE, osm.TILE_SIZE), Color(0, 0, 0))
	if data == null:
		return
	if data.has("water"):
		for w in data.water:
			draw_colored_polygon(w, Color(0, 0, 1), empty_vec2_array, null, null, true)
	if data.has("grass"):
		for g in data.grass:
			draw_colored_polygon(g, Color(0, 1, 0), empty_vec2_array, null, null, true)
	if data.has("buildings"):
		for g in data.buildings:
			draw_colored_polygon(g.points, Color(0, 0, 0), empty_vec2_array, null, null, true)
	if data.has("roads"):
		for r in data.roads:
			var width = max(1, r.width) * 0.5 + 1
			var point_count = r.points.size()
			var normals = PoolVector2Array()
			for j in range(point_count):
				normals.append(Vector2(0, 0))
			for j in range(point_count-1):
				var n = (r.points[j+1]-r.points[j]).rotated(0.5*PI).normalized()
				normals[j] += n 
				normals[j+1] += n
			var a2
			var n2
			for j in range(point_count):
				var polygon = PoolVector2Array()
				var a1 = r.points[j]
				var n1 = normals[j].normalized()*width
				if j != 0:
					polygon.append(a1-n1)
					polygon.append(a1+n1)
					polygon.append(a2+n2)
					polygon.append(a2-n2)
					draw_colored_polygon(polygon, Color(1, 0, 0), empty_vec2_array, null, null, true)
				a2 = a1
				n2 = n1
			draw_circle(r.points[0], width, Color(1, 0, 0))
			draw_circle(r.points[point_count-1], width, Color(1, 0, 0))