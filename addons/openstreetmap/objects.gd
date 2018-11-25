extends Spatial

export(int, "Trees", "Traffic lights", "Postboxes", "Fountains") var object_type = 0
export(PackedScene) var model

const OBJECT_NAMES = [ "trees", "traffic_lights", "postboxes", "fountains" ]

func _ready():
	pass

func update_data(data):
	for c in get_children():
		c.queue_free()
	for p in data[OBJECT_NAMES[object_type]]:
		var object = model.instance()
		object.translation = Vector3(p.x, 0, p.y)
		add_child(object)