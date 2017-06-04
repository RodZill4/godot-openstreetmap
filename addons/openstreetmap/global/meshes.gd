tool
extends Node

class BaseMesh:
	var primitive
	var vertices
	var colors
	var normals
	var uvs
	var uv2s
	
	func add_to_mesh(mesh, material):
		if vertices.size() > 0:
			var surface = [ vertices, normals, null, colors, uvs, uv2s, null, null, null ]
			mesh.add_surface(primitive, surface)
			mesh.surface_set_material(mesh.get_surface_count()-1, material)

class Walls:
	extends BaseMesh
	
	func _init(has_colors = true, has_uv2s = true):
		primitive = Mesh.PRIMITIVE_TRIANGLE_STRIP
		vertices = Vector3Array()
		colors = ColorArray() if has_colors else null
		normals = Vector3Array()
		uvs = Vector2Array()
		uv2s = Vector2Array() if has_uv2s else null

	func add(polygon, color, height, texture_width, texture_height, texture2_width):
		polygon.append(polygon[0])
		var p0 = polygon[0]
		vertices.append(Vector3(p0.x, height, p0.y))
		if colors != null: colors.append(color)
		normals.append(Vector3(0, 0, 0))
		uvs.append(Vector2(0, 0))
		if uv2s != null: uv2s.append(Vector2(0, 0))
		var u = 0
		var u2 = 0
		for i in range(polygon.size()-1):
			var p1 = polygon[i]
			var p2 = polygon[i+1]
			var n = Vector3(p2.x-p1.x, 0, p2.y-p1.y).cross(Vector3(0, 1, 0)).normalized()
			vertices.append(Vector3(p1.x, height, p1.y))
			if colors != null: colors.append(color)
			normals.append(n)
			uvs.append(Vector2(u, 0))
			if uv2s != null: uv2s.append(Vector2(u2, 0))
			vertices.append(Vector3(p1.x, 0, p1.y))
			if colors != null: colors.append(color)
			normals.append(n)
			uvs.append(Vector2(u, texture_height))
			if uv2s != null: uv2s.append(Vector2(u2, texture_height))
			u += (p2-p1).length() * texture_width
			u2 += floor((p2-p1).length() * texture2_width)
			vertices.append(Vector3(p2.x, height, p2.y))
			if colors != null: colors.append(color)
			normals.append(n)
			uvs.append(Vector2(u, 0))
			if uv2s != null: uv2s.append(Vector2(u2, 0))
			vertices.append(Vector3(p2.x, 0, p2.y))
			if colors != null: colors.append(color)
			normals.append(n)
			uvs.append(Vector2(u, texture_height))
			if uv2s != null: uv2s.append(Vector2(u2, texture_height))
			var v = p2-p1
			var l = v.length()
		vertices.append(Vector3(p0.x, 0, p0.y))
		if colors != null: colors.append(color)
		normals.append(Vector3(0, 0, 0))
		uvs.append(Vector2(0, 0))
		if uv2s != null: uv2s.append(Vector2(0, 0))
		return true

class Roofs:
	extends BaseMesh
	
	func _init(has_colors = false):
		primitive = Mesh.PRIMITIVE_TRIANGLES
		vertices = Vector3Array()
		colors = ColorArray() if has_colors else null
		normals = Vector3Array()
		uvs = Vector2Array()
		uv2s = null
	
	func add(polygon, height, roof_angle, color = Color(1, 1, 1)):
		roof_angle *= PI/180
		var texture_stretch = 1/cos(roof_angle)
		var geometry = load("res://addons/openstreetmap/global/geometry.gd")
		var roofs = geometry.create_straight_skeleton(polygon)
		var roof_indexes = [ ]
		for r in roofs:
			var indexes = Geometry.triangulate_polygon(r)
			if indexes.size() == 0:
				return false
			roof_indexes.append(Geometry.triangulate_polygon(r))
		for r in range(roofs.size()):
			var roof = roofs[r]
			var indexes = roof_indexes[r]
			var center = roof[0]
			var u_axis = (roof[1] - roof[0]).normalized()
			var v_axis = u_axis.rotated(0.5*PI)
			var normal = Vector3(0, 1, 0).rotated(Vector3(u_axis.x, 0, u_axis.y), -roof_angle)
			for i in range(indexes.size()):
				var a = roof[indexes[i]]
				var u = (a - center).dot(u_axis)
				var v = (a - center).dot(v_axis)
				vertices.append(Vector3(a.x, height+tan(roof_angle)*v, a.y))
				normals.append(normal)
				uvs.append(Vector2(u, -v*texture_stretch))
				if colors != null: colors.append(color)
		return true

