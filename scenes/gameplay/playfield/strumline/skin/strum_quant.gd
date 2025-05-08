extends StrumNote # TODO: this will be the base class soon so stop extending maybe??

const STATIC_COLOUR: Color = Color(0.529, 0.639, 0.678) # Bri'ish

@onready var sprite: Sprite2D = $"exterior"
@onready var interior: Sprite2D = $"exterior/interior"
@onready var plr: AnimationPlayer = $"animation_player"
# hey guys welcome to another episode of "how to workaround"
var _color_map: Dictionary[String, Color] = {}
var allow_color_overriding: bool = false
var color: Color = Color.WHITE

func _ready() -> void:
	manual_coloring() 
	super()

func manual_coloring() -> void:
	for anim_name: String in plr.get_animation_list():
		var a: Animation = plr.get_animation(anim_name)
		for b: int in a.get_track_count():
			var p: NodePath = a.track_get_path(b)
			var path: String = p.get_concatenated_names() + ":" + p.get_concatenated_subnames()
			if path == "exterior/interior:modulate":
				_color_map[anim_name] = a.track_get_key_value(b, 0)
				a.track_set_enabled(b, false)

func play_animation(state: int = StrumNote.States.STATIC, force: bool = false) -> void:
	var index: int = get_index()
	if parent: # wrap index if it's too high.
		index = index % parent.get_child_count()
	var state_name: String = StrumNote.States.keys()[state].to_lower()
	var anim_name: String = str(index) + " " + state_name
	
	if _last_state != state or force:
		plr.seek(0.0) # just to make sure
	
	plr.play(anim_name)	
	_last_state = state

	var use_static: bool = state == StrumNote.States.STATIC
	if allow_color_overriding:
		if state == StrumNote.States.PRESS:
			interior.modulate = color.darkened(0.6)
		elif not use_static:
			interior.modulate = color
	else:
		if anim_name in _color_map:
			interior.modulate = _color_map[anim_name]
		else:
			use_static = true
	if use_static:
		interior.modulate = STATIC_COLOUR
