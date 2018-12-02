extends Spatial

export(int, "Trees", "Traffic lights", "Postboxes", "Fountains") var object_type = 0
export(Array) var scenes = []

var objects = []

const OBJECT_NAMES = [ "trees", "traffic_lights", "postboxes", "fountains" ]

func _ready():
	for i in range(scenes.size()):
		objects.append([])

func update_data(data):
	var choice = scenes.size()
	for c in get_children():
		remove_child(c)
	var object_count = PoolIntArray()
	for i in range(choice):
		object_count.append(0)
	for p in data[OBJECT_NAMES[object_type]]:
		var object_index = int(p.x+p.y) % choice
		if object_count[object_index] == objects[object_index].size():
			objects[object_index].append(scenes[object_index].instance())
		var object = objects[object_index][object_count[object_index]]
		object_count[object_index] += 1
		object.translation = Vector3(p.x, 0, p.y)
		object.rotation = Vector3(0, (p.x+p.y)*6.28, 0)
		add_child(object)