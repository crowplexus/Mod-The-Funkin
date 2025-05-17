class_name StrumNote extends Node2D

enum States {
	STATIC = 0,
	PRESS = 1,
	CONFIRM = 2,
	HOLD = 3,
}

const STATIC_COLOUR: Color = Color(0.529, 0.639, 0.678) # Bri'ish

@export var allow_color_overriding: bool = false
@export var animation: AnimationPlayer
@onready var parent: Strumline

var reset_timer: float = 0.0
var reset_state: int = States.STATIC
var _last_state: int = -1
var speed: float = 1.0
# hey guys welcome to another episode of "how to workaround"
var _color_map: Dictionary[String, Color] = {}
var _real_color: Color = Color.WHITE
var color: Color = Color.WHITE

func _ready() -> void:
	if get_parent() is Strumline: parent = get_parent()
	if get_parent().get_parent() is Strumline: parent = get_parent().get_parent()
	save_colors()
	play_animation()

func get_color_state(state: int = StrumNote.States.STATIC) -> Color:
	match state:
		StrumNote.States.PRESS: return color.darkened(0.371) # 37.1% less colour
		StrumNote.States.CONFIRM: return color.lightened(0.4) # 40% more colour
		_: return color

func _process(delta: float) -> void:
	if reset_timer > 0 and _last_state != reset_state:
		reset_timer -= delta * (Conductor.crotchet * 4.0)
		if reset_timer <= 0.0: play_animation(reset_state, true)

func save_colors() -> void:
	if not animation:
		push_error("AnimationPlayer is not set in StrumNote")
		return
	for anim_name: String in animation.get_animation_list():
		var a: Animation = animation.get_animation(anim_name)
		for b: int in a.get_track_count():
			if a.track_get_type(b) != Animation.TYPE_VALUE or a.track_get_key_count(b) == 0:
				continue
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
	if parent is Strumline: # wrap index if it's too high.
		index = index % parent.strums.size()
	
	var state_name: String = StrumNote.States.keys()[state].to_lower()
	var anim_name: String = str(index) + " " + state_name
	if state == StrumNote.States.HOLD and not animation.has_animation(anim_name):
		anim_name = anim_name.replace(state_name, "confirm")
	
	if _last_state != state or force:
		animation.seek(0.0) # just to make sure
	if state != StrumNote.States.STATIC and allow_color_overriding:
		_real_color = get_color_state(state)
	animation.play(anim_name)
	_last_state = state
