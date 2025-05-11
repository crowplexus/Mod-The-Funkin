extends Note

# temporary
const HOLD_FRAMES: SpriteFrames = preload("res://assets/game/notetypes/funkin/notes.res")

@onready var animation: AnimationPlayer = $"animation_player"
@onready var splash: AnimatedSprite2D = $"splash"
@onready var splash_scale: Vector2 = splash.scale

@onready var arrow: Node2D = $"exterior"
@onready var arrow_interior: Node2D = $"exterior/interior"
var _color_map: Dictionary[String, Color] = {}
var loaded_hold: bool = false
var game: Node2D

func show_all() -> void:
	if not arrow.visible: arrow.show()
	var is_hold: bool = clip_rect and hold_size > 0.0
	if clip_rect: clip_rect.visible = is_hold
	super()

func _ready() -> void:
	if is_inside_tree(): game = get_tree().current_scene
	save_colors()
	super()

func save_colors() -> void:
	if not animation:
		push_error("AnimationPlayer is not set in Note")
		return
	for anim_name: String in animation.get_animation_list():
		var a: Animation = animation.get_animation(anim_name)
		for b: int in a.get_track_count():
			if a.track_get_type(b) != Animation.TYPE_VALUE or a.track_get_key_count(b) == 0:
				continue
			var p: NodePath = a.track_get_path(b)
			match p.get_concatenated_names() + ":" + p.get_concatenated_subnames():
				"exterior/interior:self_modulate":
					_color_map["interior_" + anim_name] = a.track_get_key_value(b, 0)
					a.track_set_enabled(b, false)
				"exterior:self_modulate":
					_color_map["exterior_" + anim_name] = a.track_get_key_value(b, 0)
					a.track_set_enabled(b, false)

func apply_color(p_time: float) -> void:
	match Global.settings.note_color_mode:
		2:  # Quant-based colouring
			var quant: int = NoteData.get_note_quant(NoteData.secs_to_row(p_time))
			arrow_interior.self_modulate = NoteData.get_quant_color(quant)
			arrow.self_modulate = arrow_interior.self_modulate.darkened(0.6)
		_:  # Default column-based colouring
			var interior_key := "interior_%d" % column
			var exterior_key := "exterior_%d" % column
			if _color_map.has(interior_key) and _color_map.has(exterior_key):
				arrow_interior.self_modulate = _color_map[interior_key]
				arrow.self_modulate = _color_map[exterior_key]
			else:
				arrow_interior.self_modulate = Color.WEB_GRAY
				arrow.self_modulate = Color.DIM_GRAY

func reload(p_data: NoteData) -> void:
	super(p_data)
	animation.play(str(column))
	apply_color(p_data.time)
	show_all()
	var is_hold: bool = clip_rect and hold_size > 0.0 and hold_body
	if is_hold:
		var color: = Note.COLORS[column % Note.COLORS.size()]
		var frames: SpriteFrames = arrow.sprite_frames if arrow is AnimatedSprite2D else HOLD_FRAMES
		hold_body.texture = frames.get_frame_texture("%s hold piece" % color, 0)
		hold_tail.texture = frames.get_frame_texture("%s hold tail" % color, 0)
		hold_tail.position.y = hold_body.get_end().y
		hold_tail.size = hold_tail.texture.get_size()
		display_hold(hold_size, get_total_speed())
		loaded_hold = true

func display_hold(size: float = 0.0, speed: float = -1.0) -> void:
	super(size, speed)
	if arrow.visible and loaded_hold: arrow.hide()
	hold_tail.position.y = hold_body.get_end().y

func can_splash() -> bool:
	return splash_type != Judgement.SplashType.DISABLED and length <= 0.0

func hold_finished() -> void:
	# testing, idk if i will add hold covers and whatever.
	if splash_type != Judgement.SplashType.DISABLED:
		display_splash()

func display_splash() -> Node2D:
	if not strumline or column == -1:
		return null
	var dip: AnimatedSprite2D = strumline.get_splash(column)
	var strum: StrumNote = strumline.get_strum(column)
	if not dip:
		dip = splash.duplicate()
		dip.name = "splash_%s" % strum.get_child_count()
		dip.animation_finished.connect(dip.hide)
		dip.top_level = true
		strum.add_child(dip)
	dip.global_position = strum.global_position
	dip.modulate.a = (game.local_settings.note_splash_alpha if Gameplay.current else Global.settings.note_splash_alpha) * 0.01
	dip.scale = splash_scale * (1.5 if splash_type == Judgement.SplashType.FULL else 1.0)
	dip.frame = 0
	dip.show()
	dip.play("note impact %s %s" %  [ randi_range(1, 2), Note.COLORS[column] ], 1.0)
	return dip

func on_note_hit() -> void:
	strumline.input.on_note_hit(self)
	if _strum.allow_color_overriding:
		_strum.color = arrow.self_modulate.lightened(0.4)
