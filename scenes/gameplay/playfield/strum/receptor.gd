class_name Receptor extends Node2D

@onready var parent: NoteField
@onready var player: AnimationPlayer = $"animation_player"
@export var sprite: Node2D

var reset_timer: float = 0.0
var reset_state: int = NoteField.RepState.STATIC
var _last_state: int = -1
var speed: float = 1.0

func _ready() -> void:
	if not sprite and  has_node("sprite"):
		sprite = get_node("sprite")
	if get_parent() is NoteField: parent = get_parent()
	play_animation(NoteField.RepState.STATIC, true)

func _process(delta: float) -> void:
	if reset_timer > 0 and _last_state != reset_state:
		reset_timer -= delta * (Conductor.crotchet * 4.0)
		if reset_timer <= 0.0: play_animation(reset_state, true)

func play_animation(state: = NoteField.RepState.STATIC, force: bool = false) -> void:
	var index: int = get_index()
	if parent: index = index % parent.get_child_count()
	if _last_state != state or force:
		player.seek(0.0)
	var state_name: String = NoteField.RepState.keys()[state].to_lower()
	player.play(str(index) + " " + state_name)
	_last_state = state
