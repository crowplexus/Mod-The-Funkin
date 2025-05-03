class_name Strumline extends Node2D

signal on_note_deleted(note: Note)

@onready var notes: Node2D = $"notes" ## Notes get sent here when spawned.
@export var strums: Array[StrumNote] = [] ## Contains the strum note sprites.
@export var input: GameInput ## Handles input, or otherwise automatic input (botplay).
@export var speed: float = 1.0 ## Note Speed for this particular strumline, is affected by the chart, may be increased by timed events.
var speed_change_tween: Tween

func get_splash(idx: int) -> Node:
	var splash: Node = null
	for child: Node in get_strum(idx).get_children():
		if child.name.begins_with("splash_"):
			if child.visible: continue
			splash = child
			break
	return splash

#region Strum Notes

func get_strum(idx: int) -> StrumNote:
	return strums[idx % strums.size()]

func play_strum(state: StrumNote.States, idx: int, force: bool = false) -> void:
	get_strum(idx).play_animation(state, force)

func set_reset_timer(idx: int = 0, timer: float = 0.5 * Conductor.crotchet) -> void:
	get_strum(idx).reset_timer = timer

func set_reset_animation(idx: int = 0, new_state: StrumNote.States = StrumNote.States.STATIC) -> void:
	get_strum(idx).reset_state = new_state

#endregion

#region Note Spawning and Movement

func _process(_delta: float) -> void:
	if notes.get_child_count() != 0:	
		for note: Note in notes.get_children():
			if not note is Note or not note.visible:
				continue
			# NOTE: nodpe is the note itself
			if note.moving: note.scroll_ahead()
			# preventing orphan nodes hopefully with this.
			if not note.was_hit and (Conductor.playhead - note.time) > 0.75:
				if note.strumline and note.strumline.input:
					var miss_delay: float = 0.75 if note.strumline.input.botplay else 0.3
					if miss_delay == 0.3 and not note.was_hit and not note.hit_misses:
						note.strumline.input.on_note_miss(note, note.column)
						note.was_missed = true
				if note: # not null by the time on_note_miss is called
					note.hide_all()
					on_note_deleted.emit(note)

#endregion
