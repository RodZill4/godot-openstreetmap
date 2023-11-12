extends Node

const variables_file_name = "user://savedata.bin"
@onready var savegame_key = null#"TW"+OS.get_unique_ID()
var variables = { "Player/Position/X": 0.0, "Player/Position/Y": 0.0 }

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
	### TODO: THIS BREAKS THE GAME
	### Invalid set index '' (on base: Transform3D') with value of type 'float'
	### variables[n] = v
	pass

func read():
#	if not FileAccess.file_exists(variables_file_name):
#		return # Read-Error, no save file detected

	var file = FileAccess.open(variables_file_name, FileAccess.READ)
	if file != null:
		variables = file.get_var()
		file.close()

func write():
#	if not FileAccess.file_exists(variables_file_name):
#		return # Write-Error, no save file detected

	var file = FileAccess.open(variables_file_name, FileAccess.WRITE)
	if file != null:
		file.store_var(variables)
		file.close()

func reset():
	variables = { }
	write()
