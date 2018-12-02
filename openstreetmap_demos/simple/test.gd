extends Spatial

onready var camera = get_node("Camera")
onready var map = get_node("Map")

var quads = []
var texture_cache = {}
var reference_position = Vector2(0, 0)
var x = null
var y = null
var event_timestamp = 0

func _ready():
	var default_pos = osm.pos2tile(5.7055, 45.18103)
	var x = default_pos.x
	var y = default_pos.y
	#x = game_state.get_var("Player/Position/X", x)
	#y = game_state.get_var("Player/Position/Y", y)
	map.reference_position = Vector2(x, y)
	map.set_center(Vector2(0, 0))

func _on_Ground_input_event(c, event, click_pos, click_normal, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.is_pressed():
				event_timestamp = OS.get_ticks_msec()
			elif OS.get_ticks_msec()-event_timestamp < 200:
				if event.doubleclick:
					pass
				elif camera != null:
					camera.set_target_pos(click_pos)
					map.set_center(Vector2(click_pos.x, click_pos.z))
