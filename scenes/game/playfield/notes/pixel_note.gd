extends Note

@onready var player: AnimationPlayer = $"animation_player"
@onready var splash: AnimatedSprite2D = $"%splash"
@onready var splash_scale: Vector2 = splash.scale

@onready var hold_body: TextureRect = $"%hold_body"
@onready var hold_tail: TextureRect = $"%hold_tail"
@onready var arrow: Node2D = $"%arrow"

var loaded_hold: bool = false
var game: Node2D

func show_all() -> void:
	if not arrow.visible: arrow.show()
	var is_hold: bool = clip_rect and hold_size > 0.0
	if clip_rect: clip_rect.visible = is_hold
	super()

func _ready() -> void:
	super()
	if is_inside_tree(): game = get_tree().current_scene

func reload(p_data: NoteData) -> void:
	super(p_data)
	player.play(str(column))
	show_all()
	var is_hold: bool = clip_rect and hold_size > 0.0 and hold_body
	if is_hold:
		var color: = Note.COLORS[column % Note.COLORS.size()]
		hold_body.texture = arrow.sprite_frames.get_frame_texture("%s hold piece" % color, 0)
		hold_tail.texture = arrow.sprite_frames.get_frame_texture("%s hold tail" % color, 0)
		hold_body.size.x = hold_body.texture.get_width()
		hold_tail.position.y = hold_body.get_end().y
		hold_tail.size = hold_tail.texture.get_size()
		stretch_hold()
		loaded_hold = true

func update_hold(delta: float) -> void:
	super(delta)
	stretch_hold()

func stretch_hold() -> void:
	if hold_body.texture:
		hold_body.size.y = calculate_hold_y_size(hold_size, get_total_speed()) #/ absf(clip_rect.scale.y)
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
	dip.play(str(Note.COLORS[column].to_lower(), randi_range(1, 3)), 1.0)
	return dip

func on_note_hit() -> void:
	if arrow.visible and hold_size > 0.0: arrow.hide()
	strumline.input.on_note_hit(self)
