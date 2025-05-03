extends StrumNote

@export var colors: PackedColorArray = [Color("#C24B99"), Color("#00FFFF"), Color("#12FA05"), Color("#F9393F")]
@onready var sprite: Sprite2D = $"sprite_2d"

func play_animation(state: int = StrumNote.States.STATIC, force: bool = false) -> void:
	if not player: # no point.
		return
	var index: int = get_index()
	var state_changed: bool = _last_state != state
	if parent: index = index % parent.get_child_count()
	if state_changed or force:
		if sprite:
			sprite.set_instance_shader_parameter("new_color", colors[index % colors.size()])
			sprite.set_instance_shader_parameter("enabled", state_changed and state != StrumNote.States.STATIC)
		player.seek(0.0)
	player.play(str(index) + " " + StrumNote.States.keys()[state].to_lower())
	_last_state = state
