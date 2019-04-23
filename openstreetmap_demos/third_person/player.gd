extends KinematicBody

export(float) var run_speed = 10.0

var map = null

var motion = Vector3(0, 0, 0)
var previous_position = Vector3(0, 0, 0)

func _ready():
	pass

func _physics_process(delta):
	motion.y += -9.8*delta
	move_and_slide(motion, Vector3(0, 1, 0))
	var direction = Vector2(0, 0)
	direction.y += run_speed*Input.get_joy_axis(0, 0)
	direction.x -= run_speed*Input.get_joy_axis(0, 1)
	if Input.is_action_pressed("ui_up"):
		direction.x += run_speed
	if Input.is_action_pressed("ui_down"):
		direction.x -= run_speed
	if Input.is_action_pressed("ui_left"):
		direction.y -= run_speed
	if Input.is_action_pressed("ui_right"):
		direction.y += run_speed
	if direction.length() > run_speed:
		direction /= direction.length()
		direction *= run_speed
	var camera = get_node("../Camera")
	if camera != null:
		direction = direction.rotated(-0.5*PI - camera.rotation.y)
	var h_motion_influence = delta
	if is_on_floor():
		h_motion_influence *= 10
		motion.y = 0
		if Input.is_action_just_pressed("jump"):
			motion.y = 10
	var h_motion = Vector2(motion.x, motion.z)
	h_motion.x = lerp(h_motion.x, direction.x, h_motion_influence)
	h_motion.y = lerp(h_motion.y, direction.y, h_motion_influence)
	if (previous_position-translation).length()/delta > 1:
		$Model.anim("Run")
		rotation.y = 0.5*PI - h_motion.angle()
	else:
		$Model.anim("Idle")
	previous_position = translation
	motion.x = h_motion.x
	motion.z = h_motion.y
	if map == null:
		map = get_node("../Map")
	else:
		map.set_center(Vector2(translation.x, translation.z))

func teleport(lat, lon):
	translation = Vector3(0, 0, 0)
	motion = Vector3(0, 0, 0)
	previous_position = Vector3(0, 0, 0)
