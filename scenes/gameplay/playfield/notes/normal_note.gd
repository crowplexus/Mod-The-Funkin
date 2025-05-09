extends Note

# temporary
const HOLD_FRAMES: SpriteFrames = preload("res://assets/game/notetypes/funkin/notes.res")

@onready var player: AnimationPlayer = $"animation_player"
@onready var splash: AnimatedSprite2D = $"splash"
@onready var splash_scale: Vector2 = splash.scale

@onready var arrow_interior: Sprite2D = $"arrow/interior"
@onready var arrow: Sprite2D = $"arrow"
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
		hold_body.texture = HOLD_FRAMES.get_frame_texture("%s hold piece" % color, 0)
		hold_tail.texture = HOLD_FRAMES.get_frame_texture("%s hold tail" % color, 0)
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
