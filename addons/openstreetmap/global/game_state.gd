extends Node

const variables_file_name = "user://savedata.bin"
onready var savegame_key = null#"TW"+OS.get_unique_ID()
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
	var f = File.new()
	var err
	if savegame_key == null:
		err = f.open(variables_file_name, File.READ)
	else:
		err = f.open_encrypted_with_pass(variables_file_name, File.READ, savegame_key)
	if err == 0:
		variables = f.get_var()
		f.close()

func write():
	var f = File.new()
	var err
	if savegame_key == null:
		err = f.open(variables_file_name, File.WRITE)
	else:
		err = f.open_encrypted_with_pass(variables_file_name, File.WRITE, savegame_key)
	if err == 0:
		f.store_var(variables)
		f.close()

func reset():
	variables = { }
	write()
