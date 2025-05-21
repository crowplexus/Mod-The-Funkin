extends TemplateHUD

## Prevents the health bar from changing colors to the ones used by the icons.
@export var keep_classic_health_colors: bool = false

@onready var score_text: Label = $"health_bar/score_text"
@onready var combo_group: Control = $"combo_group"
@onready var health_bar: ProgressBar = $"health_bar"

@onready var countdown: Control = $"countdown"
@onready var countdown_sprite: Sprite2D = $"countdown/sprite"
@onready var countdown_sound: AudioStreamPlayer = $"countdown/sound"
@onready var countdown_timer: Timer = $"countdown/timer"

@onready var icon_p1: Sprite2D = $"health_bar/icon_p1"
@onready var icon_p2: Sprite2D = $"health_bar/icon_p2"

@export var icon_zoom_mult: float = 13.0

var default_ip1_pos: Vector2 = Vector2.ZERO
var default_ip2_pos: Vector2 = Vector2.ZERO

var default_ip1_scale: Vector2 = Vector2.ONE
var default_ip2_scale: Vector2 = Vector2.ONE

var countdown_tween: Tween

var countdown_textures: Array[Texture2D] = []
var countdown_streams: Array[AudioStream] = []
var _countdown_iteration: int = 0
var _prev_health: int = 50

var _max_score: int = 0
var _min_score: int = 0

var game: Node

func _ready() -> void:
	if get_tree().current_scene:
		game = get_tree().current_scene
	if icon_p1:
		default_ip1_scale = icon_p1.scale
		default_ip1_pos = icon_p1.position
	if icon_p2:
		default_ip2_scale = icon_p2.scale
		default_ip2_pos = icon_p2.position
	if game is Gameplay:
		settings_changed(game.local_settings)
		if Gameplay.chart: _max_score = Tally.calculate_perfect_score(Gameplay.chart.note_counts[0])
	Conductor.on_beat_hit.connect(on_beat_hit)
	countdown.hide()

func _process(delta: float) -> void:
	update_health_bar(delta)
	update_icons(delta)

func _exit_tree() -> void:
	Conductor.on_beat_hit.disconnect(on_beat_hit)

func settings_changed(settings: Settings = Global.settings) -> void:
	if not settings: return
	if game is Gameplay: game.strumlines.position = game.get_strumline_position(settings)
	match settings.scroll:
		0:
			health_bar.position.y = 660
			#combo_group.position.y = 120
		1:
			#combo_group.position.y = 650
			health_bar.position.y = 65
	health_bar.self_modulate.a = settings.health_bar_alpha * 0.01
	icon_p1.self_modulate.a = settings.health_bar_alpha * 0.01
	icon_p2.self_modulate.a = settings.health_bar_alpha * 0.01

func init_vars() -> void:
	if not game.assets:
		skip_countdown = true
	else:
		countdown_textures = game.assets.countdown_assets
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
		if not countdown_timer.timeout.is_connected(countdown_progress):
			countdown_timer.timeout.connect(countdown_progress)
	setup_icons()

func setup_icons() -> void:
	if game is Gameplay:
		if game.player and game.player.icon:
			if not keep_classic_health_colors:
				var fill_style: StyleBox = health_bar.get_theme_stylebox("fill").duplicate()
				fill_style.bg_color = game.player.icon.color
				health_bar.add_theme_stylebox_override("fill", fill_style)
			if game.player.icon.texture:
				icon_p1.texture = game.player.icon.texture
				icon_p1.hframes = game.player.icon.hframes
				icon_p1.vframes = game.player.icon.vframes
		if game.enemy and game.enemy.icon:
			if not keep_classic_health_colors:
				var background_style: StyleBox = health_bar.get_theme_stylebox("background").duplicate()
				background_style.bg_color = game.enemy.icon.color
				health_bar.add_theme_stylebox_override("background", background_style)
			if game.enemy.icon.texture:
				icon_p2.texture = game.enemy.icon.texture
				icon_p2.hframes = game.enemy.icon.hframes
				icon_p2.vframes = game.enemy.icon.vframes

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
		countdown_sprite.texture = countdown_textures[_countdown_iteration]
		countdown_sprite.position = Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y) * 0.5
		countdown_sprite.scale = game.assets.countdown_scale * (1.0 if game.local_settings.simplify_popups else 1.1)
		countdown_sprite.texture_filter = game.assets.countdown_filter
		countdown_sprite.self_modulate.a = 1.0
		countdown_sprite.show()
		
		if countdown_tween: countdown_tween.stop()
		countdown_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_parallel(true)
		if countdown_sprite.scale != game.assets.countdown_scale:
			countdown_tween.tween_property(countdown_sprite, "scale", game.assets.countdown_scale, Conductor.crotchet * 0.9)
		countdown_tween.tween_property(countdown_sprite, "self_modulate:a", 0.0, Conductor.crotchet * 0.8)
		countdown_tween.finished.connect(countdown_sprite.hide)
	
	if _countdown_iteration < countdown_streams.size():
		countdown_sound.stream = countdown_streams[_countdown_iteration]
		countdown_sound.play()
	countdown_timer.start(Conductor.crotchet)
	on_countdown_tick.emit(_countdown_iteration)
	_countdown_iteration += 1

func update_score_text(_missed: bool = false) -> void:
	if Gameplay.current and Gameplay.current.player_botplay:
		score_text.text = "BotPlay Enabled"
		return
	var tally: bool = game and game.tally
	_min_score = Tally.calculate_worst_score(game.tally.notes_hit_count, game.tally.misses + game.tally.breaks)
	score_text.text  = "%s: %s" % [ tr("score", &"gameplay"), ("0" if not tally else Global.separate_thousands(game.tally.score)) ]

func update_health(health: int) -> void:
	_prev_health = health

func update_health_bar(_delta: float) -> void:
	if _prev_health != health_bar.value:
		health_bar.value = lerpf(floorf(_prev_health), health_bar.value, 0.15)

func update_icons(delta: float) -> void:
	if icon_p1 and icon_p1.scale != default_ip1_scale:
		icon_p1.scale = lerp(default_ip1_scale, icon_p1.scale, exp(-delta * icon_zoom_mult * Conductor.rate))
		icon_p1.position.x = lerpf(icon_p1.position.x, default_ip1_pos.x + ((health_bar.size.x * default_ip1_scale.x) * 0.5) - (_prev_health * 6.0), 0.05)
	if icon_p2 and icon_p2.scale != default_ip2_scale:
		icon_p2.scale = lerp(default_ip2_scale, icon_p2.scale, exp(-delta * icon_zoom_mult * Conductor.rate))
		icon_p2.position.x = lerpf(icon_p2.position.x, default_ip2_pos.x + ((health_bar.size.x * default_ip2_scale.x) * 0.5) - (_prev_health * 6.0), 0.05)
	if game is Gameplay: # this system sucks I may change it later
		if game.player and game.player.icon: icon_p1.frame = game.player.icon.get_frame(health_bar.value)
		if game.enemy and game.enemy.icon: icon_p2.frame = game.enemy.icon.get_frame(100 - health_bar.value)

func display_judgement(judgement: Judgement) -> void:
	combo_group.display_judgement(judgement.name.to_snake_case())

func display_combo(combo: int = -1) -> void:
	if combo < 0:
		return
	combo_group.display_combo(combo)

func on_beat_hit(beat: float) -> void:
	if int(beat) < 0: return
	if icon_p1: icon_p1.scale = default_ip1_scale * 1.3
	if icon_p2: icon_p2.scale = default_ip2_scale * 1.3

func get_bump_lerp(from: float = 2.0, to: float = 1.0, _delta: float = 0) -> float:
	return lerpf(from, to, _delta * 5.0)
func get_bump_lerp_vector(from: Vector2 = Vector2.ONE, to: Vector2 = Vector2.ONE, _delta: float = 0) -> Vector2:
	return lerp(from, to, _delta * 5.0)
func get_bump_scale() -> float:
	return 0.03
