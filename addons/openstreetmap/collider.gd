extends StaticBody3D

@export var ground : bool = true
@export var walls : bool = true

func _ready():
	if ground:
		var ground_shape = BoxShape3D.new()
		ground_shape.extents = Vector3(0.5*osm.TILE_SIZE, 1.0, 0.5*osm.TILE_SIZE)
		$Ground.shape = ground_shape
		$Ground.position = Vector3(0.5*osm.TILE_SIZE, -1.0, 0.5*osm.TILE_SIZE)

func update_data(data):
	if walls:
		var faces = PackedVector3Array()
		for b in data.buildings:
			var polygon = b.points
			var point_count = polygon.size()
			for j in range(point_count):
				var p1 = polygon[point_count-1 if j == 0 else j-1]
				var p2 = polygon[j]
				faces.append(Vector3(p1.x, 0, p1.y))
				faces.append(Vector3(p1.x, 10, p1.y))
				faces.append(Vector3(p2.x, 0, p2.y))
				faces.append(Vector3(p1.x, 10, p1.y))
				faces.append(Vector3(p2.x, 10, p2.y))
				faces.append(Vector3(p2.x, 0, p2.y))
		var shape = ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		$Walls.shape = shape
