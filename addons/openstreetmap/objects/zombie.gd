extends Area

onready var ray1 = get_node("RayCast1")
onready var ray2 = get_node("RayCast2")
onready var animation_player = get_node("AnimationPlayer")
onready var armature = get_node("Armature")
onready var particles = get_node("Particles")

var dead

func _ready():
	dead = false
	armature.show()
	particles.hide()
	set_rotation(Vector3(0, randf()*2*PI, 0))

func _fixed_process(delta):
	var angle = get_rotation().y
	if ray1.is_colliding():
		angle += delta
		set_rotation(Vector3(0, angle, 0))
	elif ray2.is_colliding():
		angle -= delta
		set_rotation(Vector3(0, angle, 0))
	set_translation(get_translation() + delta * 0.5 * Vector3(cos(angle), 0, -sin(angle)))

func _on_enter_screen():
	if !dead:
		animation_player.play("default")
		set_fixed_process(true)
		ray1.set_enabled(true)
		ray2.set_enabled(true)

func _on_exit_screen():
	animation_player.stop()
	set_fixed_process(false)
	ray1.set_enabled(false)
	ray2.set_enabled(false)

func _on_zombie_body_enter(body):
	dead = true
	set_fixed_process(false)
	armature.hide()
	particles.show()
	particles.set_emitting(true)