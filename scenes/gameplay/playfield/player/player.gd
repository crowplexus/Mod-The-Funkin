class_name Player
extends Node

signal hit_note(note: Note)
signal hit_hold_note(note: Note)
signal miss_note(note: Note, dir: int)

## Actions to use for controlling.
@export var controls: PackedStringArray = [ "note_left", "note_down", "note_up", "note_right" ]
## How many of the receptors are being held at a time
@export var keys_held: Array[bool] = [ false, false, false, false ]

var game: Node2D = null
var actor: Actor2D = null
var note_field: NoteField = null
var settings: Settings = Global.settings
var force_disable_input: bool = false
var note_group: Node2D

func setup() -> void:
	note_field = get_parent()
	game = get_tree().current_scene
	if game is Gameplay:
		if game.player: actor = game.player
		settings = game.local_settings
	hit_note.connect(on_note_hit)
	hit_hold_note.connect(on_hold_hit)
	miss_note.connect(on_note_miss)
	keys_held.resize(controls.size())
	keys_held.fill(false)
	if note_field:
		for idx: int in note_field.get_child_count():
			note_field.set_reset_animation(idx, NoteField.RepState.PRESSED)

func _process(delta: float) -> void:
	if not note_group: return
	for note: Note in note_group.get_children():
		if note.hold_size <= 0.0 or note.trip_timer <= 0.0 or note.side != note_field.get_index() or not note.was_hit:
			continue
		note.update_hold(delta)
		if keys_held[note.column] == true:
			note_field.play_animation(note.column, NoteField.RepState.CONFIRM, fmod(note.hold_size, 0.05) == 0)
			hit_hold_note.emit(note)
		else:
			note.trip_timer -= 0.08 * note.hold_size
		if note.trip_timer <= 0.0:
			miss_note.emit(note, note.column)
			note.dropped = true
			note.moving = true
		if note.trip_timer <= 0.0 or note.hold_size <= 0.0:
			if keys_held[note.column] == true: note_field.set_reset_timer(note.column, 0.005)
			if not note.dropped: note.hold_finished() # actually held all the way through
			note.hide_all()

func _get_note(idx: int) -> Note:
	var note: Note = null
	if not note_group: return note
	# TODO: move note groups to the strumline or whatever.
	for main: Note in note_group.get_children():
		if main.column == idx and main.side == note_field.get_index():
			var bound: bool = false
			var n_idx: int = main.get_index()
			if note_group.get_child_count() > n_idx + 1:
				var next: Note = note_group.get_child(n_idx + 1)
				bound = next.time < main.time and next.column == main.column and next.side == main.side
				if bound: note = next
			if not bound:
				note = main
			break
	return note

func _get_note_old(idx: int) -> Note:
	var note: Note = null
	if not note_group: return note
	var notes: Array = note_group.get_children().filter(func(n: Note) -> bool:
		return idx == n.column and note_field.get_index() == n.side)
	if not notes.is_empty():
		notes.sort_custom(func(a: Note, b: Note) -> bool: return a.time < b.time)
		note = notes.front()
	return note

func _unhandled_key_input(event: InputEvent) -> void:
	var idx: int = get_action_id(event)
	if not note_group or not note_field or force_disable_input or idx == -1:
		return
	var action: String = controls[idx]
	keys_held[idx % keys_held.size()] = Input.is_action_pressed(action)
	if Input.is_action_just_released(action):
		note_field.play_animation(idx, NoteField.RepState.STATIC)
		note_field.set_reset_timer(idx, 0.0)
		return
	if Input.is_action_just_pressed(action):
		var note: Note = _get_note(idx)
		if note and note.is_hittable(settings.max_hit_window):
			hit_note.emit(note)
			if note.was_hit:
				note.hit_time = note.time - Conductor.playhead
				if note.hold_size <= 0.0:
					if not note.die_later: note.hide_all()
					note_field.play_animation(idx, NoteField.RepState.CONFIRM)
					note_field.set_reset_timer(idx, 0.3)
				else:
					note.trip_timer = 1.0
					note._stupid_visual_bug = note.hit_time < 0.0
		elif not note:
			note_field.play_animation(idx, NoteField.RepState.PRESSED)
			if not settings.ghost_tapping:
				miss_note.emit(null, idx)

func on_note_hit(note: Note) -> void:
	if game is Gameplay: game.on_note_hit(note)
func on_note_miss(note: Note = null, idx: int = -1) -> void:
	if game is Gameplay: game.on_note_miss(note, idx)
func on_hold_hit(note: Note) -> void:
	if actor: actor.sing(note.column, actor.get_anim_position() > 0.1)

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
	if event.is_echo(): return id
	for garlic_bread: String in controls:
		if event.is_action(garlic_bread):
			id = garlic_bread
			break
	return id
