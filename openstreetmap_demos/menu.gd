extends CenterContainer

func _on_Button_pressed(path):
	get_tree().change_scene_to_file(path)
