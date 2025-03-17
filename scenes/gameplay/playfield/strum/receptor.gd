class_name Receptor
extends Node2D

@onready var parent: NoteField
@onready var player: AnimationPlayer = $"animation_player"
@onready var sprite: AnimatedSprite2D = $"sprite"

var reset_timer: float = 0.0
var reset_state: int = NoteField.RepState.STATIC
var _last_state: int = -1
var speed: float = 1.0


func _ready() -> void:
	parent = get_parent()
	play_animation(NoteField.RepState.STATIC, true)


func _process(delta: float) -> void:
	if reset_timer > 0 and _last_state != reset_state:
		reset_timer -= delta * (Conductor.crotchet * 4.0)
		if reset_timer <= 0.0: play_animation(reset_state, true)


func play_animation(state: = NoteField.RepState.STATIC, force: bool = false) -> void:
	if _last_state != state or force:
		sprite.frame = 0
		player.seek(0.0)
	var state_name: String = "static"
	match state:
		NoteField.RepState.PRESSED: state_name = "press"
		NoteField.RepState.CONFIRM: state_name = "confirm"
	player.play(str(get_index() % get_parent().get_child_count()) + " " + state_name)
	_last_state = state
