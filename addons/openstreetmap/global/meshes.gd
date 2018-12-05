tool
extends Node

class BaseMesh:
	var primitive
	var vertices
	var colors
	var normals
	var tangents
	var uvs
	var uv2s
	
	func add_to_mesh(mesh, material):
		if vertices.size() > 0:
			var surface = [ vertices, normals, tangents, colors, uvs, uv2s, null, null, null ]
			mesh.add_surface_from_arrays(primitive, surface)
			mesh.surface_set_material(mesh.get_surface_count()-1, material)

class Polygons:
	extends BaseMesh
	
	func _init():
		primitive = ArrayMesh.PRIMITIVE_TRIANGLES
		vertices = PoolVector3Array()
		normals = PoolVector3Array()
		uvs = PoolVector2Array()
	
	func add(polygon, height):
		var indexes = Geometry.triangulate_polygon(polygon)
		for i in range(indexes.size()):
			var a = polygon[indexes[i]]
			vertices.append(Vector3(a.x, height, a.y))
			normals.append(Vector3(0.0, 1.0, 0.0))
			uvs.append(Vector2(a.x, a.y))

class Walls:
	extends BaseMesh
	
	func _init(has_colors = true, has_uv2s = true):
		primitive = ArrayMesh.PRIMITIVE_TRIANGLE_STRIP
		vertices = PoolVector3Array()
		colors = PoolColorArray() if has_colors else null
		normals = PoolVector3Array()
		tangents = PoolRealArray()
		uvs = PoolVector2Array()
		if has_uv2s:
			uv2s = PoolVector2Array()
		else:
			uv2s = null

	func add_uv2(x, y):
		uv2s.append(Vector2(x, y))

	func add(polygon, color, height, texture_width, texture_height, texture2_width):
		polygon.append(polygon[0])
		var p0 = polygon[0]
		var t0 = PoolRealArray([0, 0, 0, 0])
		vertices.append(Vector3(p0.x, height, p0.y))
		if colors != null: colors.append(color)
		normals.append(Vector3(0, 0, 0))
		tangents.append_array(t0)
		if uv2s != null:
			uvs.append(Vector2(0, 0))
			add_uv2(0, 0)
		else:
			uvs.append(Vector2(0, 0))
		var u = 0
		for i in range(polygon.size()-1):
			var p1 = polygon[i]
			var p2 = polygon[i+1]
			var n = Vector3(p2.x-p1.x, 0, p2.y-p1.y).cross(Vector3(0, 1, 0)).normalized()
			var t = Vector3(p2.x-p1.x, 0, p2.y-p1.y).normalized()
			t = PoolRealArray([t.x, t.y, t.z, 1])
			var u2 = floor((p2-p1).length() * texture2_width)
			var u2_gap = (p2-p1).length()*texture2_width/u2 if u2 != 0 else 1.0
			vertices.append(Vector3(p1.x, height, p1.y))
			normals.append(n)
			tangents.append_array(t)
			if uv2s != null:
				uvs.append(Vector2(0, u2_gap))
				add_uv2(u, 0)
			else:
				uvs.append(Vector2(u, 0))
			vertices.append(Vector3(p1.x, 0, p1.y))
			normals.append(n)
			tangents.append_array(t)
			if uv2s != null:
				uvs.append(Vector2(0, u2_gap))
				add_uv2(u, texture_height)
			else:
				uvs.append(Vector2(u, texture_height))
			u += (p2-p1).length() * texture_width
			vertices.append(Vector3(p2.x, height, p2.y))
			normals.append(n)
			tangents.append_array(t)
			if uv2s != null:
				uvs.append(Vector2(u2, u2_gap))
				add_uv2(u, 0)
			else:
				uvs.append(Vector2(u, 0))
			vertices.append(Vector3(p2.x, 0, p2.y))
			normals.append(n)
			tangents.append_array(t)
			if uv2s != null:
				uvs.append(Vector2(u2, u2_gap))
				add_uv2(u, texture_height)
			else:
				uvs.append(Vector2(u, texture_height))
			u = u-floor(u)
			if colors != null:
				colors.append(color)
				colors.append(color)
				colors.append(color)
				colors.append(color)
		vertices.append(Vector3(p0.x, 0, p0.y))
		if colors != null: colors.append(color)
		normals.append(Vector3(0, 0, 0))
		tangents.append_array(t0)
		if uv2s != null:
			uvs.append(Vector2(0, 0))
			add_uv2(0, 0)
		else:
			uvs.append(Vector2(0, 0))
		return true

class ConvexRoofs:
	extends BaseMesh
	
	func _init(has_colors = false):
		primitive = ArrayMesh.PRIMITIVE_TRIANGLES
		vertices = PoolVector3Array()
		colors = PoolColorArray() if has_colors else null
		normals = PoolVector3Array()
		tangents = PoolRealArray()
		uvs = PoolVector2Array()
		uv2s = null
	
	func add(polygon, height, roof_angle, color = Color(1, 1, 1)):
		roof_angle *= PI/180
		var s = polygon.size()
		var center = Vector2(0, 0)
		for p in polygon:
			center += p
		center /= s
		var min_dist = 100000
		for i in range(s):
			var p1 = polygon[i]
			var p2 = polygon[(i+1)%s]
			var dist = (Geometry.get_closest_point_to_segment_2d(center, p1, p2)-center).length()
			if dist < min_dist:
				min_dist = dist
		var center_3 = Vector3(center.x, height + min_dist * tan(roof_angle), center.y)
		for i in range(s):
			var p1 = polygon[i]
			var p1_3 = Vector3(p1.x, height, p1.y)
			var p2 = polygon[(i+1)%s]
			var p2_3 = Vector3(p2.x, height, p2.y)
			var texture_stretch = sqrt(tan(roof_angle)*tan(roof_angle)+1)
			var u_axis = (p2 - p1).normalized()
			var v_axis = u_axis.rotated(0.5*PI)*texture_stretch
			var normal = (p2_3 - p1_3).cross(center_3-p1_3).normalized()
			var tangent = (p2_3 - p1_3).normalized()
			tangent = PoolRealArray([tangent.x, tangent.y, tangent.z, 1])
			vertices.append(p1_3)
			normals.append(normal)
			tangents.append_array(tangent)
			uvs.append(Vector2(0, 0))
			vertices.append(center_3)
			normals.append(normal)
			tangents.append_array(tangent)
			uvs.append(Vector2((center-p1).dot(u_axis), (center-p1).dot(v_axis)))
			vertices.append(p2_3)
			normals.append(normal)
			tangents.append_array(tangent)
			uvs.append(Vector2((p2 - p1).length(), 0))
			if colors != null:
				colors.append(color)
				colors.append(color)
				colors.append(color)
		return true

class Roofs:
	extends BaseMesh
	
	func _init(has_colors = false):
		primitive = ArrayMesh.PRIMITIVE_TRIANGLES
		vertices = PoolVector3Array()
		colors = PoolColorArray() if has_colors else null
		normals = PoolVector3Array()
		tangents = PoolRealArray([])
		uvs = PoolVector2Array()
		uv2s = null
	
	func add(polygon, height, roof_angle, color = Color(1, 1, 1)):
		roof_angle *= PI/180
		var texture_stretch = 1/cos(roof_angle)
		var geometry = load("res://addons/openstreetmap/global/geometry.gd")
		var roofs = geometry.create_straight_skeleton(polygon)
		var roof_indexes = []
		for r in roofs:
			var indexes = Geometry.triangulate_polygon(r)
			if indexes.size() == 0:
				return false
			roof_indexes.append(indexes)
		for r in range(roofs.size()):
			var roof = roofs[r]
			var indexes = roof_indexes[r]
			var center = roof[0]
			var u_axis = (roof[1] - roof[0]).normalized()
			var v_axis = u_axis.rotated(0.5*PI)
			var tangent = (Vector3(u_axis.x, 0, u_axis.y)).normalized()
			var normal = Vector3(0, 1, 0).rotated(tangent, roof_angle)
			tangent = PoolRealArray([tangent.x, tangent.y, tangent.z, 1])
			for i in range(indexes.size()):
				var a = roof[indexes[i]]
				var u = (a - center).dot(u_axis)
				var v = (a - center).dot(v_axis)
				vertices.append(Vector3(a.x, height-tan(roof_angle)*v, a.y))
				normals.append(normal)
				tangents.append_array(tangent)
				uvs.append(Vector2(u, v*texture_stretch))
				if colors != null: colors.append(color)
		return true

