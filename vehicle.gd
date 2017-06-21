
extends VehicleBody

# member variables here, example:
# var a=2
# var b="textvar"

const STEER_SPEED=1
const STEER_LIMIT=0.4

var steer_angle=0
var steer_target=0

export var engine_force=40

func _fixed_process(delta):
	var force = 0
	steer_target=0
	if (Input.is_action_pressed("ui_left")):
		steer_target -= STEER_LIMIT
	if (Input.is_action_pressed("ui_right")):
		steer_target += STEER_LIMIT
	if (Input.is_action_pressed("ui_up")):
		force += engine_force
	if (Input.is_action_pressed("ui_down")):
		force -= engine_force
	set_engine_force(force)
	set_brake(10 if Input.is_action_pressed("ui_select") else 0)
	if (steer_target < steer_angle):
		steer_angle -= STEER_SPEED*delta
		if (steer_target > steer_angle):
			steer_angle=steer_target
	elif (steer_target > steer_angle):
		steer_angle += STEER_SPEED*delta
		if (steer_target < steer_angle):
			steer_angle=steer_target
	set_steering(steer_angle)

func _ready():
	# Initalization here
	set_fixed_process(true)
	pass


