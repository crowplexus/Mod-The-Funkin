extends TemplateHUD

const POPUP_SCALE: Vector2 = Vector2(1.5, 1.5)
const SCORE_TRANSLATE_CONTEXT: StringName = &"gameplay"

@onready var score_text: Label = $"text_ui/score"
@onready var score_value: Control = $"text_ui/counter"
@onready var health_text: Label = $"health_bar/health_percent"
@onready var accuracy_text: Label = $"accuracy_bar/accuracy_progress"
@onready var judgement_popup: Label = $"text_ui/judgement_popup"

@onready var health_bar: ProgressBar = $"%health_bar"
@onready var shield_bar: ProgressBar = $"%accuracy_bar" # this is accuracy not time btw

@onready var countdown: Control = $"countdown"
@onready var countdown_sprite: Sprite2D = $"countdown/sprite"
@onready var countdown_sound: AudioStreamPlayer = $"countdown/sound"
@onready var countdown_timer: Timer = $"countdown/timer"

var countdown_tween: Tween
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
		settings_changed(game.local_settings)
		if Gameplay.chart:
			# minimum score wasn't really necessary, but eh.
			_max_score = Tally.calculate_perfect_score(Gameplay.chart.note_counts[0])
			_min_score = Tally.calculate_worst_score(Gameplay.chart.note_counts[0])
	countdown.hide()

func _process(_delta: float) -> void:
	if health_bar.value != _prev_health:
		health_bar.value = lerp(health_bar.value, floorf(_prev_health), 0.05)

func settings_changed(settings: Settings = Global.settings) -> void:
	if not settings: return
	match settings.scroll:
		0:
			if game is Gameplay:
				game.strumlines.position.y = 0
			score_value.position.y = 680
			score_text.position.y = 580
			health_bar.position.y = 660
			shield_bar.position.y = 645
		1:
			if game is Gameplay:
				game.strumlines.position.y = 500
			score_value.position.y = 80
			score_text.position.y = 10
			health_bar.position.y = 50
			shield_bar.position.y = 35
	health_bar.self_modulate.a = settings.health_bar_alpha * 0.01

func init_vars() -> void:
	if not game.assets:
		skip_countdown = true
	else:
		countdown_streams = game.assets.countdown_sounds
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
	if _countdown_iteration < countdown_streams.size():
		countdown_sound.stream = countdown_streams[_countdown_iteration]
		countdown_sound.play()
	countdown_timer.start(Conductor.crotchet)
	on_countdown_tick.emit(_countdown_iteration)
	_countdown_iteration += 1

func update_score_text(_missed: bool = false) -> void:
	var tally: bool = game and game.tally
	if tally:
		score_value.value = game.tally.score
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
	judgement_popup.modulate = new_modulate
	if not game.local_settings.simplify_popups: judgement_popup.scale = POPUP_SCALE
	judgement_popup.text = "%s\nx%s" % [ latest_judge.name, combo ]
	if popup_tween: popup_tween.kill()
	judgement_popup.show()
	popup_tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	if judgement_popup.scale != POPUP_SCALE:
		popup_tween.tween_property(judgement_popup, "scale", Vector2.ONE, 0.3).set_delay(Conductor.crotchet * 0.1)
	popup_tween.tween_property(judgement_popup, "modulate:a", 0.0, 0.5).set_delay(Conductor.crotchet * 1.0) \
	.finished.connect(judgement_popup.hide)

func get_bump_lerp(from: float = 2.0, to: float = 1.0, _delta: float = 0) -> float:
	return lerpf(from, to, _delta * 5.0)
func get_bump_lerp_vector(from: Vector2 = Vector2.ONE, to: Vector2 = Vector2.ONE, _delta: float = 0) -> Vector2:
	return lerp(from, to, _delta * 5.0)
func get_bump_scale() -> float:
	return 0.05
