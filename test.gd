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
	print(osm.TILE_SIZE)
	var default_pos = osm.pos2tile(45.18103, 5.7055)
	var x = game_state.get_var("Player/Position/X", default_pos.x)
	var y = game_state.get_var("Player/Position/Y", default_pos.y)
	map.reference_position = Vector2(x, y)
	map.set_center(Vector2(0, 0))

func _on_Ground_input_event(c, event, click_pos, click_normal, shape_idx):
	if event.type == InputEvent.MOUSE_BUTTON:
		if event.button_index == BUTTON_LEFT:
			if event.is_pressed():
				event_timestamp = OS.get_ticks_msec()
			elif OS.get_ticks_msec()-event_timestamp < 200:
				if event.doubleclick:
					pass
				else:
					camera.set_target_pos(click_pos)
