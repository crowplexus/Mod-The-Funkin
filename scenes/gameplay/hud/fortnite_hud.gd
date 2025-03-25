extends TemplateHUD

@onready var score_text: Label = $"health_bar/score_text"
@onready var health_text: Label = $"health_bar/health_percent"
@onready var accuracy_text: Label = $"accuracy_bar/accuracy_progress"

@onready var combo_group: Control = $"combo_group"
@onready var note_fields: Control = $"note_fields"
@onready var health_bar: ProgressBar = $"%health_bar"
@onready var shield_bar: ProgressBar = $"%accuracy_bar" # this is accuracy not time btw

@onready var countdown: Control = $"countdown"
@onready var countdown_sprite: Sprite2D = $"countdown/sprite"
@onready var countdown_sound: AudioStreamPlayer = $"countdown/sound"
@onready var countdown_timer: Timer = $"countdown/timer"

var countdown_tween: Tween

var countdown_textures: Array[Texture2D] = []
var countdown_streams: Array[AudioStream] = []
var _countdown_iteration: int = 0
var _prev_health: int = 50

var game: Node2D

func _ready() -> void:
	if get_tree().current_scene and get_tree().current_scene is Node2D:
		game = get_tree().current_scene
	_on_settings_changed(game.local_settings if game is Gameplay else Global.settings)
	countdown.hide()

func _process(_delta: float) -> void:
	if health_bar.value != _prev_health:
		health_bar.value = lerp(health_bar.value, floorf(_prev_health), 0.05)

func _on_settings_changed(settings: Settings) -> void:
	if not settings: return
	match settings.scroll:
		0:
			note_fields.position.y = 0
			health_bar.position.y = 660
			shield_bar.position.y = 645
		1:
			note_fields.position.y = 500
			health_bar.position.y = 50
			shield_bar.position.y = 35

func init_vars() -> void:
	if not game.assets:
		skip_countdown = true
	else:
		countdown_textures = game.assets.countdown_textures
		countdown_streams = game.assets.countdown_sounds
		if not countdown_sprite:
			countdown_sprite = Sprite2D.new()
			countdown_sprite.name = "sprite"
			countdown.add_child(countdown_sprite)
		if not countdown_sound:
			countdown_sound = AudioStreamPlayer.new()
			countdown_sound.name = "sound"
			countdown.add_child(countdown_sound)
		if not countdown_timer:
			countdown_timer = Timer.new()
			countdown_timer.name = "timer"
			countdown_timer.one_shot = true
			countdown.add_child(countdown_timer)
		countdown_timer.timeout.connect(countdown_progress)

func start_countdown() -> void:
	countdown.show()
	countdown_timer.start(Conductor.crotchet)
	_countdown_iteration = 0

func countdown_progress() -> void:
	if _countdown_iteration >= 4:
		on_countdown_end.emit()
		countdown_timer.stop()
		countdown.hide()
		return
	
	if _countdown_iteration < countdown_textures.size():
		const SCALE: Vector2 = Vector2(0.7, 0.7)
		countdown_sprite.texture = countdown_textures[_countdown_iteration]
		countdown_sprite.position = Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y) * 0.5
		countdown_sprite.self_modulate.a = 1.0
		countdown_sprite.scale = SCALE * 1.05
		countdown_sprite.show()
		
		if countdown_tween: countdown_tween.stop()
		countdown_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_parallel(true)
		countdown_tween.tween_property(countdown_sprite, "scale", SCALE, Conductor.crotchet * 0.9)
		countdown_tween.tween_property(countdown_sprite, "self_modulate:a", 0.0, Conductor.crotchet * 0.8)
		countdown_tween.finished.connect(countdown_sprite.hide)
	
	if _countdown_iteration < countdown_streams.size():
		countdown_sound.stream = countdown_streams[_countdown_iteration]
		countdown_sound.play()
	countdown_timer.start(Conductor.crotchet)
	on_countdown_tick.emit(_countdown_iteration)
	_countdown_iteration += 1

func update_score_text() -> void:
	var tally: bool = game and game.tally
	var total_misses: int = game.tally.misses + game.tally.breaks
	var fc_string: String = game.tally.get_tier_grade()
	score_text.text = tr("info_bar", &"gameplay") % [
		(game.tally.score if tally else 0),
		(game.tally.combo if tally else 0),
		(fc_string if tally and not fc_string.is_empty() else str(total_misses) if tally else str(0)),
	]
	if tally:
		accuracy_text.text = "%s%%" % [ snappedf(game.tally.accuracy, 0.001) if tally else 0.0 ]
		shield_bar.value = clampf(game.tally.accuracy, 0.0, 100.0)

func update_health(health: int) -> void:
	health_text.text = "%s%%" % health
	_prev_health = health

func display_judgement(image: Texture2D) -> void:
	combo_group.display_judgement(image)

func display_combo(combo: int = -1) -> void:
	if combo < 5:
		# TODO: miss combo
		return
	combo_group.display_combo(combo)

func get_bump_lerp(from: float = 2.0, to: float = 1.0, _delta: float = 0) -> float:
	return lerpf(from, to, 0.05) # TODO: use exp()
func get_bump_lerp_vector(from: Vector2 = Vector2.ONE, to: Vector2 = Vector2.ONE, _delta: float = 0) -> Vector2:
	return Global.lerpv2(from, to, 0.05) # TODO: use exp()
func get_bump_scale() -> float:
	return 0.03
