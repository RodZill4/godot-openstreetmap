extends Node

static func fix_polygon(polygon):
	if (polygon[0]-polygon[polygon.size()-1]).length() < 0.5:
		polygon.remove(polygon.size()-1)
	return polygon

static func polygon_has_problems(polygon):
	var problems = 0
	var s = polygon.size()
	for i in range(s):
		for j in range(i+2, polygon.size()):
			if (j+1) % s == i:
				continue
			var p = Geometry.segment_intersects_segment_2d(polygon[i], polygon[(i+1) % s], polygon[j], polygon[(j+1) % s])
			if p != null:
				problems += 1
				print(p)
				#print("problem: "+str(i)+"-"+str((i+1)%s)+" intersects "+str(j)+"-"+str((j+1) % s)+"   "+str((polygon[(i+1) % s]-polygon[j]).length()))
	if problems > 0:
		print("polygon has "+str(problems)+" problems")
	return problems

static func polygon_is_convex(polygon):
	var s = polygon.size()
	for i in range(s):
		var p1 = polygon[(i+s-1) % s]
		var p2 = polygon[i]
		var p3 = polygon[(i+1) % s]
		var angle = (p3-p2).angle_to(p1-p2)
		if sin(angle) < 0:
			return false
	return true

static func polygon_area(polygon):
	var area = 0.0
	for i in range(polygon.size()):
		var p1 = polygon[(i-1) if (i > 0) else (polygon.size()-1)]
		var p2 = polygon[i]
		area += p1.x*p2.y
		area -= p1.y*p2.x
	return 0.5*area

static func reverse_polygon(polygon):
	var size = polygon.size()
	for i in range(size/2):
		var tmp = polygon[i]
		polygon[i] = polygon[size-i-1]
		polygon[size-i-1] = tmp

static func triangles_area(vectices, indexes):
	var area = 0
	for i in range(indexes.size()/3):
		var a = vectices[indexes[3*i]]
		var b = vectices[indexes[3*i+1]]
		var c = vectices[indexes[3*i+2]]
		area += 0.5*abs(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y))
	return area

func triangulate_polygon(polygon):
	var triangles = PoolIntArray()
	var s = polygon.size()
	var expected_size = (s-2)*3
	var vertices = PoolIntArray()
	for i in range(s):
		vertices.append(i)
	while vertices.size() > 2:
		var ears = []
		s = vertices.size()
		var p1
		var p2
		var p3
		for i in range(s-1, -1, -1):
			p1 = polygon[vertices[(i+s-1) % s]]
			p2 = polygon[vertices[i]]
			p3 = polygon[vertices[(i+1) % s]]
			var angle = (p3-p2).angle_to(p1-p2)
			if sin(angle) >= 0:
				ears.append(i)
		for i in ears:
			var new_s = vertices.size()
			triangles.append(vertices[i])
			triangles.append(vertices[(i+new_s-1) % new_s])
			triangles.append(vertices[(i+1) % new_s])
			vertices.remove(i)
			if vertices.size() < 3:
				break
		if s == vertices.size():
			break
	return triangles

# straight skeleton creation algorithm

class PointList:
	var p = null
	var prev = null
	var next = null
	
	func _init():
		pass
	
	# add an element after self
	func add(p):
		var l = get_script().new()
		l.p = p
		l.prev = self
		l.next = self.next
		self.next.prev = l
		self.next = l
		return l
	
	func remove():
		var rv
		if next == self:
			rv = null
		else:
			prev.next = next
			next.prev = prev
			rv = next
		next = null
		prev = null
		return rv

# create a list from a Vector2 array
static func pl_create(c, l):
	var rv = null
	for p in l:
		if rv == null:
			rv = c.new()
			rv.p = p
			rv.next = rv
			rv.prev = rv
		else:
			rv.prev.add(p)
	return rv
	
static func add_face_point(location, point, update_location = true):
	var new_point
	if location.after:
		new_point = location.point.add(point)
	else:
		new_point = location.point.prev.add(point)
	if update_location:
		location.point = new_point
	return new_point

static func create_straight_skeleton(polygon, canvas_item = null, epsilon = 0.01):
	var s
	var points = [ ]
	var faces = [ ]
	var queue = [ ]
	s = polygon.size()
	for i in range(s):
		var p1 = polygon[i]
		var p2 = polygon[(i + 1) if (i != s - 1) else 0]
		points.append( { p = p1 } )
		faces.append(pl_create(PointList, [ p1, p2 ]))
	var first_pass = true
	while true:
		s = points.size()
		for i2 in range(s):
			var i1 = (i2 - 1) if (i2 != 0) else (s - 1)
			var i3 = (i2 + 1) if (i2 != s - 1) else 0
			var p1 = points[i1].p
			var p2 = points[i2].p
			var p3 = points[i3].p
			if canvas_item != null: canvas_item.draw_line(p1, p2, Color(1, 0, 0))
			var b = (p1-p2).normalized()+(p3-p2).normalized()
			var angle = 0.5*(p1-p2).angle_to(p3-p2)
			b = b.normalized() / sin(angle)
			points[i2].b = b
			points[i2].is_reflex = (sin(angle) < 0)
			if first_pass:
				points[i2].left_face = { point = faces[i1].next, after = true }
				points[i2].right_face = { point = faces[i2], after = false }
		var min_t = -1
		for i in range(s):
			var p1 = points[i]
			var p2 = points[(i + 1) if (i != s - 1) else 0]
			var a = p1.b-p2.b
			var b = p1.p-p2.p
			if a != Vector2(0, 0):
				var t
				if abs(a.y) > abs(a.x):
					t = -b.y/a.y
				else:
					t = -b.x/a.x
				if t > 0 && (min_t < 0 || t < min_t):
					min_t = t
		var split = null
		for i in range(s):
			var p = points[i]
			if !p.is_reflex:
				continue
			for j1 in range(s):
				var j2 = (j1 + 1) if (j1 != s - 1) else 0
				if i == j1 || i == j2:
					continue
				var p1 = points[j1]
				var p2 = points[j2]
				var u = (p2.p - p1.p).normalized()
				var normal = Vector2(u.y, -u.x)
				var speed = p.b.dot(normal)
				if speed > 0:
					continue
				var d = ((p1.p - p.p) - (p1.p - p.p).dot(u) * u).length()
				var t = d / (1-speed)
				var pi = p.p + t*p.b
				var pj1 = p1.p + t*p1.b
				var pj2 = p2.p + t*p2.b
				if (pj1 - pj2).length() == 0 || (pi - pj1).length() > (pj2 - pj1).length() || (pi - pj2).length() > (pj2 - pj1).length():
					continue
				if t >= 0 && (min_t < 0 || t < min_t):
					min_t = t
					split = { i = i, j1 = j1, j2 = j2 }
		if min_t < 0:
			if queue.empty():
				break
			else:
				points = queue.back()
				queue.pop_back()
				continue
		for i in range(s):
			if canvas_item != null: canvas_item.draw_line(points[i].p, points[i].p + min_t*points[i].b, Color(0, 0, 1))
			points[i].p += min_t*points[i].b
		if split != null:
			if canvas_item != null:
				canvas_item.draw_circle(points[split.i].p, 10, Color(0, 1, 0))
				canvas_item.draw_line(points[split.j1].p, points[split.j2].p, Color(0, 1, 0), 10)
			var p = points[split.i].p
			add_face_point(points[split.i].left_face, p)
			add_face_point(points[split.i].right_face, p)
			var new_point = add_face_point(points[split.j1].right_face, p, false)
			for i in range(split.i):
				points.append(points[0])
				points.pop_front()
			split.j1 -= split.i
			if split.j1 < 0: split.j1 += s
			split.j2 -= split.i
			if split.j2 < 0: split.j2 += s
			split.i = 0
			p = points[0]
			var new_points = [ { p = p.p, left_face = p.left_face, right_face = p.right_face } ]
			for i in range(s-split.j2):
				new_points.insert(1, points.back())
				points.pop_back()
			points[split.i].left_face = { point = new_point, after = true }
			new_points[0].right_face = { point = new_point, after = false }
			queue.append(new_points)
			s = points.size()
		for i in range(s-1, -1, -1):
			var p1 = points[i].p
			var i2 = (i + 1) if (i != points.size() - 1) else 0
			var p2 = points[i2].p
			if (p1-p2).length() < epsilon:
				add_face_point(points[i].right_face, p1)
				add_face_point(points[i].left_face, p1)
				add_face_point(points[i2].right_face, p1)
				points[i2].left_face = { point = points[i].left_face.point, after = points[i].left_face.after }
				points.remove(i)
		first_pass = false
	for f in range(faces.size()):
		var pl = faces[f]
		points = []
		var last_point = null
		while pl != null:
			if last_point == null || (pl.p-last_point).length() > epsilon:
				points.append(pl.p)
				last_point = pl.p
			pl = pl.remove()
		faces[f] = points
	return faces

# polygon clamping algorithm

static func is_inside_edge(p, e):
	return e.a*p.x+e.b*p.y+e.c >= 0

static func intersect_line_with_edge(p1, p2, e):
	var r1 = e.a*p1.x+e.b*p1.y+e.c
	var r2 = e.a*p2.x+e.b*p2.y+e.c
	return (r2*p1-r1*p2)/(r2-r1)

static func clamp_polygon(polygon, rect):
	var output = polygon
	for l in [ { a=1, b=0, c=-rect.position.x }, { a=0, b=1, c=-rect.position.y }, { a=-1, b=0, c=rect.end.x }, { a=0, b=-1, c=rect.end.y } ]:
		var input = output
		output = PoolVector2Array()
		var s = input[input.size()-1]
		for e in input:
			if is_inside_edge(e, l):
				if !is_inside_edge(s, l):
					output.append(intersect_line_with_edge(e, s, l))
				output.append(e)
			elif is_inside_edge(s, l):
				output.append(intersect_line_with_edge(e, s, l))
			s = e
	return output
