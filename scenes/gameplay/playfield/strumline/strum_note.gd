class_name StrumNote extends Node2D

enum States {
	STATIC = 0,
	PRESS = 1,
	CONFIRM = 2,
}

const STATIC_COLOUR: Color = Color(0.529, 0.639, 0.678) # Bri'ish

@export var animation: AnimationPlayer
@onready var parent: StrumNote

var reset_timer: float = 0.0
var reset_state: int = States.STATIC
var _last_state: int = -1
var speed: float = 1.0
# hey guys welcome to another episode of "how to workaround"
var _color_map: Dictionary[String, Color] = {}
var allow_color_overriding: bool = false
var color: Color = Color.WHITE

func _ready() -> void:
	manual_coloring()
	if get_parent() is StrumNote:
		parent = get_parent()
	play_animation()

func _process(delta: float) -> void:
	if reset_timer > 0 and _last_state != reset_state:
		reset_timer -= delta * (Conductor.crotchet * 4.0)
		if reset_timer <= 0.0: play_animation(reset_state, true)

func manual_coloring() -> void:
	if not animation:
		push_error("AnimationPlayer is not set in StrumNote")
		return
	for anim_name: String in animation.get_animation_list():
		var a: Animation = animation.get_animation(anim_name)
		for b: int in a.get_track_count():
			var p: NodePath = a.track_get_path(b)
			var path: String = p.get_concatenated_names() + ":" + p.get_concatenated_subnames()
			if path == "exterior/interior:modulate":
				_color_map[anim_name] = a.track_get_key_value(b, 0)
				a.track_set_enabled(b, false)

func play_animation(state: int = StrumNote.States.STATIC, force: bool = false) -> void:
	if not animation:
		push_error("AnimationPlayer is not set in StrumNote")
		return
	var index: int = get_index()
	if parent: # wrap index if it's too high.
		index = index % parent.get_child_count()
	var state_name: String = StrumNote.States.keys()[state].to_lower()
	var anim_name: String = str(index) + " " + state_name
	
	if _last_state != state or force:
		animation.seek(0.0) # just to make sure
	
	animation.play(anim_name)
	_last_state = state
