extends Camera3D

@export var align : float = 0

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func _physics_process(delta):
	var player = get_node("../Player")
	if player != null:
		var direction = player.position - position
		var h_direction = Vector2(direction.x, direction.z)
		rotation.y = -0.5*PI - h_direction.angle()
		h_direction = 2*(h_direction.length() - 3) * h_direction.normalized()
		var round_direction = Vector3(0, 0, 0)
		position += delta * Vector3(h_direction.x, 0, h_direction.y)
		if align != 0:
			var round_position = Vector3(align*round(position.x/align), position.y, align*round(position.z/align))
			position += delta * (round_position - position)
