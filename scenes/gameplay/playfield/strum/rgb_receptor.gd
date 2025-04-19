extends Receptor

@export var colors: PackedColorArray = [Color("#C24B99"), Color("#00FFFF"), Color("#12FA05"), Color("#F9393F")]

func play_animation(state: = NoteField.RepState.STATIC, force: bool = false) -> void:
	var state_changed: bool = _last_state != state
	var index: int = get_index()
	if parent: index = index % parent.get_child_count()
	var enable_shader: bool = state_changed and state != NoteField.RepState.STATIC
	if state_changed or force:
		if sprite:
			sprite.set_instance_shader_parameter("new_color", colors[index % colors.size()])
			sprite.set_instance_shader_parameter("enabled", enable_shader)
			sprite.frame = 0
		player.seek(0.0)
	var state_name: String = NoteField.RepState.keys()[state].to_lower()
	player.play(str(index) + " " + state_name)
	_last_state = state
