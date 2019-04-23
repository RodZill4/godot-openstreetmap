extends VehicleBody

# member variables here, example:
# var a=2
# var b="textvar"

const STEER_SPEED = 1
const STEER_LIMIT = 0.4

var steer_angle = 0
var steer_target = 0

var map = null

export var max_engine_force = 40

func _physics_process(delta):
	var force = 0
	var brake_action = Input.is_action_pressed("ui_select")
	steer_target=0
	if (Input.is_action_pressed("ui_left")):
		steer_target += STEER_LIMIT
	if (Input.is_action_pressed("ui_right")):
		steer_target -= STEER_LIMIT
	if (Input.is_action_pressed("ui_up")):
		force += max_engine_force
	if (Input.is_action_pressed("ui_down")):
		force -= max_engine_force
	set_engine_force(force)
	set_brake(10 if brake_action else 0)
	if (steer_target < steer_angle):
		steer_angle -= STEER_SPEED*delta
		if (steer_target > steer_angle):
			steer_angle=steer_target
	elif (steer_target > steer_angle):
		steer_angle += STEER_SPEED*delta
		if (steer_target < steer_angle):
			steer_angle=steer_target
	set_steering(steer_angle)
	if force < 0 || brake_action:
		$BackLights.show()
	else:
		$BackLights.hide()
	if map == null:
		map = get_node("../Map")
	else:
		map.set_center(Vector2(translation.x, translation.z))

func teleport(lat, lon):
	translation = Vector3(0, 0, 0)
