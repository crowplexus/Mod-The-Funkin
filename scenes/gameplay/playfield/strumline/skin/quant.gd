extends StrumNote

@onready var interior: Sprite2D = $"exterior/interior"

func play_animation(state: int = StrumNote.States.STATIC, force: bool = false) -> void:
	super.play_animation(state, force)
	var index: int = get_index()
	if parent: # wrap index if it's too high.
		index = index % parent.get_child_count()
	var anim_name: String = str(index) + " " + StrumNote.States.keys()[state].to_lower()
	var use_static: bool = state == StrumNote.States.STATIC
	if allow_color_overriding:
		if state == StrumNote.States.PRESS:
			interior.modulate = color.darkened(0.6)
		elif not use_static:
			interior.modulate = color
	else:
		if anim_name in _color_map:
			interior.modulate = _color_map[anim_name]
		else:
			use_static = true
	if use_static:
		interior.modulate = STATIC_COLOUR
