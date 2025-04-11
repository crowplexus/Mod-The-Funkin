extends Note

@onready var player: AnimationPlayer = $"animation_player"
@onready var splash: AnimatedSprite2D = $"splash"
@onready var arrow: AnimatedSprite2D = $"arrow"

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
	if not arrow.visible: arrow.show_all()
	var is_hold: bool = arrow.sprite_frames and clip_rect and hold_size > 0.0 and hold_body
	if is_hold:
		var color: = Note.COLORS[column % Note.COLORS.size()]
		hold_body.texture = arrow.sprite_frames.get_frame_texture("%s hold piece" % color, 0)
		hold_tail.texture = arrow.sprite_frames.get_frame_texture("%s hold tail" % color, 0)
		hold_tail.size = hold_tail.texture.get_size()
		hold_tail.position.y = hold_body.get_end().y
		display_hold(hold_size, get_total_speed())
		loaded_hold = true

func display_hold(size: float = 0.0, speed: float = -1.0) -> void:
	super(size, speed)
	if arrow.visible and loaded_hold: arrow.hide()
	hold_tail.position.y = hold_body.get_end().y

func can_splash() -> bool:
	return judgement and judgement.splash_type != Judgement.SplashType.DISABLED and length <= 0.0

func hold_finished() -> void:
	# testing, idk if i will add hold covers and whatever.
	if judgement and judgement.splash_type != Judgement.SplashType.DISABLED:
		display_splash()

func display_splash() -> Node2D:
	if not note_field or column == -1:
		return null
	var dip: AnimatedSprite2D = note_field.get_splash(column)
	var receptor: Receptor = note_field.get_receptor(column)
	if not dip:
		dip = splash.duplicate()
		dip.name = "splash_%s" % receptor.get_child_count()
		dip.animation_finished.connect(dip.hide)
		dip.global_position = receptor.global_position
		dip.top_level = true
		receptor.add_child(dip)
	dip.modulate.a = (game.local_settings.note_splash_alpha if Gameplay.current else Global.settings.note_splash_alpha) * 0.01
	dip.scale = Vector2.ONE * (1.0 if judgement.splash_type == Judgement.SplashType.FULL else 0.8)
	dip.frame = 0
	dip.show()
	dip.play("note impact %s %s" %  [ randi_range(1, 2), Note.COLORS[column] ], 1.0)
	return dip
