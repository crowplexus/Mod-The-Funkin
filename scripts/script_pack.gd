class_name ScriptPack extends Node

var scripts: Array[Node]

func _ready() -> void:
	scripts = get_children()

## Clears any null scripts from the array.
func cleanup() -> void:
	for i: int in scripts.size():
		if not is_instance_valid(scripts[i]):
			scripts.remove_at(i)

## Calls a function inside the scripts.
func call_func(signature: StringName, arguments: Array = []) -> void:
	for script: Node in scripts: if script.has_method(signature): script.callv(signature, arguments)

func load_global_scripts() -> void:
	var path: String = "res://assets/game/scripts/"
	if DirAccess.dir_exists_absolute(path):
		push_scripts_only(path)

func load_song_scripts(song: String, difficulty: String = "") -> void:
	var path: String = "res://assets/game/songs/%s/scripts/" % song
	if DirAccess.dir_exists_absolute(path):
		var next: String = path
		if DirAccess.dir_exists_absolute(path + difficulty):
			next = path + difficulty
		push_scripts_only(next)

func push_scripts_only(path: String) -> void:
	for file: String in DirAccess.get_files_at(path):
		if file.get_extension() == "gd":
			var script: GDScript = load(path.path_join(file))
			if script: add_child(script.new())
			print_debug("loading script ", path.path_join(file))
	cleanup()
