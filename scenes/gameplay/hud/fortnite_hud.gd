extends TemplateHUD

const POPUP_SCALE: Vector2 = Vector2(1.5, 1.5)

@onready var score_text: Label = $"health_bar/score_text"
@onready var health_text: Label = $"health_bar/health_percent"
@onready var accuracy_text: Label = $"accuracy_bar/accuracy_progress"
@onready var judgement_popup: Label = $"judgement_popup"

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

var _max_score: int = 0
var _min_score: int = 0

# judgement popup shit #
var latest_judge: Judgement
var popup_tween: Tween
# # # # # # # # #
var game: Node2D

func _ready() -> void:
	if get_tree().current_scene and get_tree().current_scene is Node2D:
		game = get_tree().current_scene
	if game is Gameplay:
		_on_settings_changed(game.local_settings)
		if Gameplay.chart:
			# minimum score wasn't really necessary, but eh.
			_max_score = Tally.calculate_perfect_score(Gameplay.chart.note_counts[0])
			_min_score = Tally.calculate_worst_score(Gameplay.chart.note_counts[0])
	countdown.hide()

func _process(_delta: float) -> void:
	if health_bar.value != _prev_health:
		health_bar.value = lerp(health_bar.value, floorf(_prev_health), 0.05)

func _on_settings_changed(settings: Settings = Global.settings) -> void:
	if not settings: return
	match settings.scroll:
		0:
			if game is Gameplay:
				game.note_fields.position.y = 0
			health_bar.position.y = 660
			shield_bar.position.y = 645
		1:
			if game is Gameplay:
				game.note_fields.position.y = 500
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

func update_score_text(_missed: bool = false) -> void:
	var tally: bool = game and game.tally
	var total_misses: int = game.tally.misses + game.tally.breaks
	var fc_string: String = game.tally.get_tier_grade()
	score_text.text = tr("info_bar", &"gameplay") % [
		Global.separate_thousands(game.tally.score if tally else 0),
		str(game.tally.combo if tally else 0),
		str(total_misses if tally else 0),
	]
	if fc_string:
		score_text.text += " [%s]" % fc_string
	if tally:
		_min_score = Tally.calculate_worst_score(game.tally.notes_hit_count, game.tally.misses + game.tally.breaks)
		var accuracy_score: float = Tally.calculate_score_percentage(game.tally.score, _max_score, _min_score)
		accuracy_text.text = "%.2f%%" % accuracy_score
		shield_bar.value = accuracy_score

func update_health(health: int) -> void:
	health_text.text = "%s%%" % health
	_prev_health = health

func display_judgement(judgement: Judgement) -> void:
	latest_judge = judgement

func display_combo(combo: int = -1) -> void:
	var new_modulate: Color = latest_judge.color if latest_judge else Color.WHITE
	if combo < 0:
		new_modulate = Color.PALE_VIOLET_RED
	judgement_popup.scale = POPUP_SCALE
	judgement_popup.modulate = new_modulate
	judgement_popup.text = "%s\nx%s" % [ latest_judge.name, combo ]
	if popup_tween: popup_tween.kill()
	judgement_popup.show()
	popup_tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	popup_tween.tween_property(judgement_popup, "scale", Vector2.ONE, 0.3).set_delay(Conductor.crotchet * 0.1)
	popup_tween.tween_property(judgement_popup, "modulate:a", 0.0, 0.5).set_delay(Conductor.crotchet * 1.0) \
	.finished.connect(judgement_popup.hide)

func get_bump_lerp(from: float = 2.0, to: float = 1.0, _delta: float = 0) -> float:
	return lerpf(from, to, 0.05) # TODO: use exp()
func get_bump_lerp_vector(from: Vector2 = Vector2.ONE, to: Vector2 = Vector2.ONE, _delta: float = 0) -> Vector2:
	return Global.lerpv2(from, to, 0.05) # TODO: use exp()
func get_bump_scale() -> float:
	return 0.03
