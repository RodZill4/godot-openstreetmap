extends Node2D

var roads = []
var buildings = []
var grass = []
var water = []

var terrain_map = null
const TERRAIN_DIRT     = 0
const TERRAIN_GRASS    = 1
const TERRAIN_NONE     = 2
const TERRAIN_STREET   = 3

class TerrainMap:
	var image
	const IMAGE_SIZE = 256
	
	func _init():
		var image_size = IMAGE_SIZE*(IMAGE_SIZE >> 3)
		image = PoolIntArray()
		image.resize(image_size)
		for i in range(image_size):
			image[i] = 0
	
	func _get(x, y):
		if x >= 0 && x < IMAGE_SIZE && y >= 0 && y < IMAGE_SIZE:
			x = int(x)
			y = int(y)
			return (image[y*(IMAGE_SIZE >> 3)+(x>>3)] >> ((x&7)*2)) & 3
		else:
			return TERRAIN_NONE

	func get(x, y):
		return _get(int(x * IMAGE_SIZE / osm.TILE_SIZE), int(y * IMAGE_SIZE / osm.TILE_SIZE))

	func _set(x, y, c):
		if x >= 0 && x < IMAGE_SIZE && y >= 0 && y < IMAGE_SIZE:
			var i = y*(IMAGE_SIZE >> 3)+(x>>3)
			var d = (x&7)*2
			image[i] = (image[i] & ~(3 << d)) | (c << d)
	
	func _hline(x1, x2, y, c):
		if y < 0 || y >= IMAGE_SIZE:
			return
		if x1 > x2:
			var tmp = x1
			x1 = x2
			x2 = tmp
		if x1 < 0:
			x1 = 0
		if x2 >= IMAGE_SIZE:
			x2 = IMAGE_SIZE-1
		if x1 <= x2:
			for x in range(x1, x2+1):
				_set(x, y, c)
	
	func _trapezoid(xa1, xa2, ya, xb1, xb2, yb, color):
		var dy = yb - ya
		if dy == 0:
			pass
			#_hline(int(min(min(xa1, xa2), min(xb1, xb2))), int(max(max(xa1, xa2), max(xb1, xb2))), ya, color)
		elif dy < 0:
			print("error")
		else:
			var dx1 = xb1 - xa1
			var dx2 = xb2 - xa2
			for y in range(ya, yb+1):
				var x1 = int(xa1 + dx1 * (y - ya) / dy)
				var x2 = int(xa2 + dx2 * (y - ya) / dy)
				_hline(x1, x2, y, color)
	
	func _draw_triangle(p1, p2, p3, color):
		var tmp
		if p1.y > p2.y:
			tmp = p1
			p1 = p2
			p2 = tmp
		if p2.y > p3.y:
			tmp = p2
			p2 = p3
			p3 = tmp
		if p1.y > p2.y:
			tmp = p1
			p1 = p2
			p2 = tmp
		var xmid
		if p1.y == p2.y:
			xmid = p1.x
		else:
			xmid = p1.x + int((p3.x-p1.x)*(p2.y-p1.y)/(p3.y-p1.y))
			_trapezoid(p1.x, p1.x, p1.y, p2.x, xmid, p2.y, color)
		_trapezoid(p2.x, xmid, p2.y, p3.x, p3.x, p3.y, color)
	
	func draw_triangle(p1, p2, p3, color):
		var ip1 = { x= int(p1.x * IMAGE_SIZE / osm.TILE_SIZE), y= int(p1.y * IMAGE_SIZE / osm.TILE_SIZE) }
		var ip2 = { x= int(p2.x * IMAGE_SIZE / osm.TILE_SIZE), y= int(p2.y * IMAGE_SIZE / osm.TILE_SIZE) }
		var ip3 = { x= int(p3.x * IMAGE_SIZE / osm.TILE_SIZE), y= int(p3.y * IMAGE_SIZE / osm.TILE_SIZE) }
		_draw_triangle(ip1, ip2, ip3, color)
	
	func draw_polygon(polygon, color):
		var indices = Geometry.triangulate_polygon(polygon)
		for i in range(0, indices.size(), 3):
			draw_triangle(polygon[indices[i]], polygon[indices[i+1]], polygon[indices[i+2]], color)

func _ready():
	pass

func init():
	roads = []
	buildings = []
	grass = []
	water = []

func do_draw(tmap = false):
	if tmap:
		for b in buildings:
			terrain_map.draw_polygon(b, TERRAIN_NONE)
		for w in water:
			terrain_map.draw_polygon(w, TERRAIN_NONE)
		for g in grass:
			terrain_map.draw_polygon(g, TERRAIN_GRASS)
	else:
		draw_rect(Rect2(0, 0, 1000, 1000), Color(0, 0, 0))
		for w in water:
			draw_colored_polygon(w, Color(0, 0, 1))
		for g in grass:
			draw_colored_polygon(g, Color(0, 1, 0))
	for r in roads:
		var width = max(1, r.width) * 0.5
		if tmap:
			width += 1
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
				if tmap:
					terrain_map.draw_polygon(polygon, TERRAIN_STREET)
				else:
					draw_colored_polygon(polygon, Color(1, 0, 0))
			a2 = a1
			n2 = n1
		if !tmap:
			draw_circle(r.points[0], width, Color(1, 0, 0))
			draw_circle(r.points[point_count-1], width, Color(1, 0, 0))

func _draw():
	do_draw()

func generate_image():
	terrain_map = TerrainMap.new()
	do_draw(true)

func free_image():
	terrain_map = null

func get_terrain_type(x, y):
	return terrain_map.get(x, y)

