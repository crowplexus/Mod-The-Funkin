extends Player

func _ready() -> void:
	note_field = get_parent()
	if get_tree().current_scene:
		game = get_tree().current_scene
	hit_note.connect(on_note_hit)
	set_process_input(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
	set_process_shortcut_input(false)

func _process(delta: float) -> void:
	if not note_group: return
	for note: Note in note_group.get_children():
		if note.time <= Conductor.playhead and note.side == note_field.get_index():
			hit_note.emit(note)
			note.was_hit = true
			var was_hold: bool = note.hold_size > 0.0
			if note.hold_size > 0.0:
				note.update_hold(delta)
				if fmod(note.hold_size, 0.05) == 0:
					note_field.play_animation(note.column, NoteField.RepState.CONFIRM)
					hit_hold_note.emit(note)
				note.allowed_to_hide = true
			if note.hold_size <= 0.0:
				if was_hold: note_field.play_animation(note.column, NoteField.RepState.STATIC)
				note_group.on_note_deleted.emit(note)
				note.hide_all()

func on_note_hit(note: Note) -> void:
	note_field.play_animation(note.column, NoteField.RepState.CONFIRM)
	note_field.set_reset_timer(note.column, 0.3 * Conductor.crotchet)
	if get_tree().current_scene is Gameplay:
		get_tree().current_scene.enemy.sing(note.column, true)
