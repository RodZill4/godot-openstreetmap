extends Node3D

@onready var camera = get_node("Camera")
@onready var map = get_node("Map")

var quads = []
var texture_cache = {}
var reference_position = Vector2(0, 0)
var x = null
var y = null
var event_timestamp = 0

func _ready():
	teleport(48.7419, 9.1008)

func _on_Ground_input_event(_c, event, click_pos, _click_normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				event_timestamp = Time.get_ticks_msec()
			elif Time.get_ticks_msec()-event_timestamp < 200:
				if event.double_click:
					pass
				elif camera != null:
					camera.set_target_pos(click_pos)
					map.set_center(Vector2(click_pos.x, click_pos.z))

func teleport(lat : float, lon : float):
	if map != null:
		var default_pos = osm.pos2tile(lon, lat)
		x = default_pos.x
		y = default_pos.y
		map.reference_position = Vector2(x, y) # reference_position?
		map.set_center(Vector2(0, 0))
