extends Spatial

onready var rotate_y = get_node("RotateY")
onready var rotate_x = get_node("RotateY/RotateX")
onready var camera = get_node("RotateY/RotateX/Camera")
var moving = false
var target_pos = Vector3(0, 0, 0)
var zoom = 1 setget set_zoom,get_zoom

var drag = false
var touch_pos = Vector2(0, 0)

signal moved_to(p)

func _ready():
	set_physics_process(true)
	set_process_input(true)

func set_target_pos(pos):
	var abs_pos = get_node("../Map").reference_position + Vector2(pos.x, pos.z)/osm.TILE_SIZE
	print("Moving to "+str(Vector2(abs_pos.x, abs_pos.y)))
	game_state.set_var("Player/Position/X", abs_pos.x)
	game_state.set_var("Player/Position/Y", abs_pos.y)
	game_state.write()
	target_pos = Vector3(pos.x, 0, pos.z)
	moving = true

func get_zoom():
	return zoom

func set_zoom(z):
	zoom = z
	if zoom < 1: zoom = 1
	if zoom > 10: zoom = 10
	rotate_camera(0, 0)
	camera.set_perspective(60, zoom, zoom*750)

func rotate_camera(rx, ry):
	var r = rotate_y.get_rotation()
	rotate_y.set_rotation(Vector3(r.x, r.y+ry, r.z))
	r = rotate_x.get_rotation()
	var angle = max(0, min(1.25, r.x-0.004*rx))
	rotate_x.set_rotation(Vector3(angle, r.y, r.z))
	camera.set_translation(zoom * Vector3(0, 100-62*angle*angle, 0))

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			drag = event.is_pressed()
			touch_pos = event.position
		elif event.is_pressed() && event.button_index == BUTTON_WHEEL_DOWN:
			set_zoom(get_zoom()*1.05)
		elif event.is_pressed() && event.button_index == BUTTON_WHEEL_UP:
			set_zoom(get_zoom()/1.05)
	if event is InputEventMouseMotion && drag:
		var rx = event.position.y-touch_pos.y
		var ry = -0.004*(event.position.x-touch_pos.x)
		rotate_camera(rx, ry)
		touch_pos = event.position

func _physics_process(delta):
	if moving:
		var t = get_translation()
		t += 150*delta*(target_pos-t).normalized()
		set_translation(t)
		if (target_pos-t).length() < 10:
			moving = false
	else:
		var translate_x = 0
		var translate_y = 0
		var translate_z = 0
		if Input.is_action_pressed("ui_left"):
			translate_x -= 1
		if Input.is_action_pressed("ui_right"):
			translate_x += 1
		if Input.is_action_pressed("ui_up"):
			translate_y -= 1
		if Input.is_action_pressed("ui_down"):
			translate_y += 1
		if translate_x != 0 || translate_y != 0:
			var direction = 50*Vector2(translate_x, translate_y).rotated(rotate_y.get_rotation().y)
			if Input.is_action_pressed("run"):
				direction *= 3
			set_translation(get_translation()+delta*Vector3(direction.x, 0, direction.y))
		else:
			return
	emit_signal("moved_to", Vector2(get_translation().x, get_translation().z))
