class_name StrumNote extends Node2D

enum States {
	STATIC = 0,
	PRESS = 1,
	CONFIRM = 2,
}

@onready var parent: StrumNote
@export var player: AnimationPlayer

var reset_timer: float = 0.0
var reset_state: int = States.STATIC
var _last_state: int = -1
var speed: float = 1.0

func _ready() -> void:
	if get_parent() is StrumNote:
		parent = get_parent()
	play_animation()

func _process(delta: float) -> void:
	if reset_timer > 0 and _last_state != reset_state:
		reset_timer -= delta * (Conductor.crotchet * 4.0)
		if reset_timer <= 0.0: play_animation(reset_state, true)

func play_animation(state: int = StrumNote.States.STATIC, force: bool = false) -> void:
	if not player: # no point.
		return
	var index: int = get_index()
	if parent: index = index % parent.get_child_count()
	if _last_state != state or force: player.seek(0.0)
	player.play(str(index) + " " + StrumNote.States.keys()[state].to_lower())
	_last_state = state
