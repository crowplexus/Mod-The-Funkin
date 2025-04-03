extends Player

func setup() -> void:
	note_field = get_parent()
	if get_tree().current_scene:
		game = get_tree().current_scene
		if game is Gameplay:
			if game.enemy: actor = game.enemy
			settings = game.local_settings
	hit_note.connect(on_note_hit)
	set_process_input(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
	set_process_shortcut_input(false)

func _process(delta: float) -> void:
	if not note_group: return
	for note: Note in note_group.get_children():
		if note.side != note_field.get_index():
			continue
		var was_hold: bool = note.hold_size > 0.0
		if note.time <= Conductor.playhead and not note.was_hit:
			hit_note.emit(note)
			note.was_hit = true
		if note.was_hit:
			if note.hold_size > 0.0:
				note.update_hold(delta)
				note_field.play_animation(note.column, NoteField.RepState.CONFIRM, fmod(note.hold_size, 0.05) == 0)
				hit_hold_note.emit(note)
				on_hold_hit(note)
			if note.hold_size <= 0.0:
				if was_hold:
					note_field.set_reset_timer(note.column, 0.005)
					if not note.dropped: note.hold_finished()
				note_group.on_note_deleted.emit(note)
				note.hide_all()

func on_note_hit(note: Note) -> void:
	note_field.play_animation(note.column, NoteField.RepState.CONFIRM)
	note_field.set_reset_timer(note.column, 0.3 * (Conductor.crotchet + note.length))
	# TODO: rewrite this to attach characters to the notefield or something like that.
	if actor: actor.sing(note.column, true)
	if game is Gameplay and game.music and not game.has_enemy_track:
		game.music.stream.set_sync_stream_volume(1, linear_to_db(1.0))

func on_hold_hit(note: Note) -> void:
	if actor and not actor.cheering_out:
		actor.sing(note.column, actor.get_anim_position() > 0.1)
