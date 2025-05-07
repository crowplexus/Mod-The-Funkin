class_name GameInput extends Node

signal hit_note(note: Note)
signal hit_hold_note(note: Note)
signal miss_note(note: Note, dir: int)

@export var controls: Array[String] = [ "note_left", "note_down", "note_up", "note_right" ]
@export var keys_held: Array[bool] = [ ]
@export var botplay: bool = true:
	set(_botplay):
		botplay = _botplay
		set_process_input(not _botplay)
		set_process_unhandled_input(not _botplay)
		set_process_unhandled_key_input(not _botplay)
		if strumline:
			for i: int in strumline.strums.size():
				var s: int = StrumNote.States.STATIC if _botplay else StrumNote.States.PRESS
				strumline.set_reset_animation(i, s)
@export var strumline: Strumline

var settings: Settings
var game: Gameplay

func setup() -> void:
	keys_held.resize(controls.size())
	keys_held.fill(false)
	if Gameplay.current:
		game = Gameplay.current
	if not strumline: strumline = get_parent()
	# TODO: Gameplay.current.local_settings
	settings = Global.settings

func _process(delta: float) -> void:
	if strumline and strumline.notes and strumline.notes.get_child_count() != 0:
		if Conductor.time > -0.05:
			for note: Note in strumline.notes.get_children():
				if botplay and note.time <= Conductor.time and not note.was_hit:
					note.hit_by_bot = true
					note.on_note_hit()
				var miss_delay: float = 0.75 if botplay else 0.3
				# preventing orphan nodes hopefully with this.
				if not note.was_hit and (Conductor.playhead - note.time) > miss_delay:
					if miss_delay == 0.3 and not note.was_hit:
						note.on_note_miss()
					if note: # not null by the time on_note_miss is called
						note.hide_all()
						strumline.on_note_deleted.emit(note)
		update_holds(delta)

#region Note Callbacks

func on_note_hit(note: Note) -> void:
	hit_note.emit(note)
	if botplay:
		note.was_hit = true
		if note.hold_size <= 0.0:
			note.hide_all()
		strumline.play_strum(StrumNote.States.CONFIRM, note.column)
		strumline.set_reset_timer(note.column, 0.45 * (Conductor.crotchet + note.length))
	if game:
		if not botplay:
			game.on_note_hit(note)
		else:
			# TODO: attach characters to the strumline or something like that.
			var actor: Actor2D = game.get_actor_from_index(note.side)
			if actor: actor.sing(note.column, true)
			if Conductor.is_music_playing() and not game.has_enemy_track:
				Conductor.set_music_volume(1.0, 1)

func on_note_miss(note: Note = null, idx: int = -1) -> void:
	miss_note.emit(note, note.column)
	if game: game.on_note_miss(note, idx)

func on_hold_hit(note: Note) -> void:
	hit_hold_note.emit(note)
	if game:
		var actor: Actor2D = game.get_actor_from_index(note.side)
		if actor and actor.able_to_sing: actor.sing(note.column, actor.get_anim_position() > 0.1)

#endregion

#region Player Input

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_echo() or botplay or not strumline or not strumline.notes:
		return
	var idx: int = get_action_id(event) % keys_held.size()
	if idx < 0: return
	
	var action: String = controls[idx]
	keys_held[idx] = Input.is_action_pressed(action)
	if event.is_released():
		strumline.play_strum(StrumNote.States.STATIC, idx)
		if strumline.get_strum(idx).reset_timer > 0.0:
			strumline.set_reset_timer(idx, 0.0)
		return
	var note: Note = _get_note(idx)
	if note and note.is_hittable(settings.max_hit_window):
		note.on_note_hit()
		if note.was_hit:
			note.hit_time = note.time - Conductor.playhead
			if note.hold_size <= 0.0:
				note.hide_all()
				if note._strum._last_state != StrumNote.States.PRESS:
					strumline.play_strum(StrumNote.States.CONFIRM, idx)
				strumline.set_reset_timer(idx, 0.2)
			else:
				note.trip_timer = 0.5 # half a second
				note._stupid_visual_bug = note.hit_time < 0.0
	else:
		strumline.play_strum(StrumNote.States.PRESS, idx)
		if not settings.ghost_tapping: on_note_miss(null, idx)

func get_action_id(event: InputEvent) -> int:
	var id: int = -1
	if event.is_echo(): return id
	for garlic_bread: int in controls.size():
		if event.is_action(controls[garlic_bread]):
			id = garlic_bread
			break
	return id

func get_action_name(event: InputEvent) -> String:
	var id: String
	for garlic_bread: String in controls:
		if event.is_action(garlic_bread):
			id = garlic_bread
			break
	return id

func _get_note(idx: int) -> Note:
	var note: Note = null
	if not strumline or not strumline.notes: return note
	for main: Note in strumline.notes.get_children():
		if main.column == idx:
			var bound: bool = false
			var n_idx: int = main.get_index()
			if strumline.notes.get_child_count() > n_idx + 1:
				var next: Note = strumline.notes.get_child(n_idx + 1)
				bound = next.time < main.time and next.column == main.column
				if bound: note = next
			if not bound:
				note = main
			break
	return note

func _get_note_old(idx: int) -> Note:
	var note: Note = null
	if not strumline or not strumline.notes: return note
	var notes: Array = strumline.notes.get_children().filter(func(n: Note) -> bool: return idx == n.column)
	if not notes.is_empty():
		notes.sort_custom(func(a: Note, b: Note) -> bool: return a.time < b.time)
		note = notes.front()
	return note

#endregion

func update_holds(delta: float) -> void:
	for note: Note in strumline.notes.get_children():
		if not note.visible or note.hold_size <= 0.0 or note.trip_timer <= 0.0 or not note.was_hit:
			continue
		
		# TODO: move this to Note._process without breaking anything
		note.update_hold(delta)
		
		var trip_decay: float = 0.01 # needs to be nerfed for rolls?
		var must_trip: bool = keys_held[note.column] == false
		if note.kind.begins_with("roll"): # invert the condition
			must_trip = not must_trip
		if botplay:
			must_trip = false
		# hit the note if you didn't trip
		if not must_trip:
			strumline.play_strum(StrumNote.States.CONFIRM, note.column, fmod(note.hold_size, 0.05) == 0)
			if note.modulate.a < 1.0: note.modulate.a = 1.0
			on_hold_hit(note)
			if note.hold_size <= 0.0 and botplay:
				strumline.set_reset_timer(note.column, 0.01)
		if must_trip and note.hold_size > 0.045: # nerf hold dropping by a few seconds. (Bopeebo)
			note.trip_timer -= trip_decay / note.hold_size
			note.modulate.a -= 5 * delta
		# miss note if you dropped it completely.
		if note.trip_timer <= 0.0:
			note.on_note_miss()
			note.dropped = true
			note.moving = true
		# delete the note if you're done holding or dropped it.
		if note.hold_size <= 0.0 and keys_held[note.column] == true:
			strumline.set_reset_timer(note.column, 0.005)
			if not note.dropped: note.hold_finished()
			note.hide_all()
