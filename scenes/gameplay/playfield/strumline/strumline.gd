class_name Strumline extends Node2D

@warning_ignore("unused_signal") # it's used elsewhere shut the fuck up.
signal on_note_deleted(note: Note)

@onready var notes: Node2D = $"notes" ## Notes get sent here when spawned.
@export var strums: Array[StrumNote] = [] ## Contains the strum note sprites.
@export var input: GameInput ## Handles input, or otherwise automatic input (botplay).
@export var speed: float = 1.0 ## Note Speed for this particular strumline, is affected by the chart, may be increased by timed events.
@export var skin: NoteSkin

var speed_change_tween: Tween

func reload_skin() -> void:
	if not skin: return
	for strum: StrumNote in strums:
		if skin.strum_scene.resource_path == strum.scene_file_path:
			return
		strum.queue_free()
		var new_thing: StrumNote = skin.strum_scene.instantiate()
		new_thing.position = (strum.position * (self.scale * new_thing.scale))
		var index: int = strums.find(strum)
		new_thing.name = str(index)
		add_child(new_thing)
		strums[index] = new_thing
		move_child(new_thing, index)

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
