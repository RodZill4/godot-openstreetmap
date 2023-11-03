extends Node

const variables_file_name = "user://savedata.save"
@onready var savegame_key = null#"TW"+OS.get_unique_ID()
var variables = { }

func _ready():
	print("game state ready")
	read()

# user configuration

func get_var(n, d):
	if variables.has(n):
		return variables[n]
	else:
		return d

func set_var(n, v):
	variables[n] = v

func read():
	if not FileAccess.file_exists(variables_file_name):
		return # Read-Error, no save file detected

	var file
	if savegame_key == null:
		file = FileAccess.open(variables_file_name, FileAccess.READ)
	else:
		file = FileAccess.open_encrypted_with_pass(variables_file_name, FileAccess.READ, savegame_key)
	if file != null:
		variables = file.get_var()
	file.close()

func write():
	if not FileAccess.file_exists(variables_file_name):
		return # Write-Error, no save file detected

	var file
	if savegame_key == null:
		file = FileAccess.open(variables_file_name, FileAccess.WRITE)
	else:
		file = FileAccess.open_encrypted_with_pass(variables_file_name, FileAccess.WRITE, savegame_key)
	if file != null:
		file.store_var(variables)
	file.close()

func reset():
	variables = { }
	write()
