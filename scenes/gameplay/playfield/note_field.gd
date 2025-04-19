## Gameplay Object that usually contains 4 sprites,
## visually representing a player's playfield.
class_name NoteField extends Node2D

enum RepState {
	STATIC = 0,
	PRESS = 1,
	CONFIRM = 2,
}

@export var player: Player ## Player Node attached to this note field, will try to set automatically if null.
@export var speed: float = 1.0 ## Note Speed for this particular note field, is affected by the chart, may be increased by timed events.
var speed_change_tween: Tween

func _ready() -> void:
	if not player and has_node("player"):
		player = get_node("player")

func get_receptor(idx: int) -> Node:
	return get_child(idx % get_child_count())

func get_splash(idx: int) -> Node:
	var splash: Node = null
	var receptor: = get_receptor(idx)
	for child: Node in receptor.get_children():
		if child.name.begins_with("splash_"):
			if child.visible: continue
			splash = child
			break
	return splash

func play_animation(idx: int = 0, state: = NoteField.RepState.STATIC, force: bool = true) -> void:
	var receptor: = get_child(idx % get_child_count())
	if receptor is Receptor and receptor.has_method("play_animation"):
		receptor.play_animation(state, force)

func set_reset_timer(idx: int = 0, timer: float = 0.5 * Conductor.crotchet) -> void:
	var receptor: = get_receptor(idx)
	if receptor is Receptor: receptor.reset_timer = timer

func set_reset_animation(idx: int = 0, new_state: = NoteField.RepState.STATIC) -> void:
	var receptor: = get_receptor(idx)
	if receptor is Receptor: receptor.reset_state = new_state
