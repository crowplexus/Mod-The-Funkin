extends TemplateHUD

## Prevents the health bar from changing colors to the ones used by the icons.
@export var keep_classic_health_colors: bool = false

@onready var score_text: Label = $"health_bar/score_text"
@onready var misses_text: Label = $"health_bar/misses_text"

@onready var combo_group: Control = $"combo_group"
@onready var note_fields: Control = $"note_fields"
@onready var health_bar: ProgressBar = $"health_bar"

@onready var countdown: Control = $"countdown"
@onready var countdown_sprite: Sprite2D = $"countdown/sprite"
@onready var countdown_sound: AudioStreamPlayer = $"countdown/sound"
@onready var countdown_timer: Timer = $"countdown/timer"

@onready var icon_p1: Sprite2D = $"health_bar/icon_p1"
@onready var icon_p2: Sprite2D = $"health_bar/icon_p2"

var default_ip1_pos: Vector2 = Vector2.ZERO
var default_ip2_pos: Vector2 = Vector2.ZERO

var default_ip1_scale: Vector2 = Vector2.ONE
var default_ip2_scale: Vector2 = Vector2.ONE

var countdown_tween: Tween

var countdown_textures: Array[Texture2D] = []
var countdown_streams: Array[AudioStream] = []
var _countdown_iteration: int = 0
var _prev_health: int = 50

var game: Node2D

func _ready() -> void:
	if get_tree().current_scene and get_tree().current_scene is Node2D:
		game = get_tree().current_scene
	Conductor.on_beat_hit.connect(on_beat_hit)
	if icon_p1:
		default_ip1_pos = icon_p1.position
		default_ip1_scale = icon_p1.scale
	if icon_p2:
		default_ip2_pos = icon_p2.position
		default_ip2_scale = icon_p2.scale
	print_debug(default_ip1_pos, default_ip2_pos)
	_on_settings_changed(game.local_settings if game is Gameplay else Global.settings)
	countdown.hide()

func _process(delta: float) -> void:
	if health_bar.value != _prev_health:
		health_bar.value = lerp(health_bar.value, floorf(_prev_health), 0.05)
	if icon_p1 and icon_p1.scale != default_ip1_scale:
		icon_p1.scale = Global.lerpv2(default_ip1_scale, icon_p1.scale, exp(-delta * 20.0 * Conductor.rate))
		icon_p1.position.x = lerpf(icon_p1.position.x, default_ip1_pos.x + (health_bar.size.x * 0.51) - (_prev_health * 6.0), 0.05)
	if icon_p2 and icon_p2.scale != default_ip2_scale:
		icon_p2.scale = Global.lerpv2(default_ip2_scale, icon_p2.scale, exp(-delta * 20.0 * Conductor.rate))
		icon_p2.position.x = lerpf(icon_p2.position.x, default_ip2_pos.x + (health_bar.size.x * 0.51) - (_prev_health * 6.0), 0.05)
		

func _exit_tree() -> void:
	Conductor.on_beat_hit.disconnect(on_beat_hit)

func _on_settings_changed(settings: Settings) -> void:
	if not settings: return
	match settings.scroll:
		0:
			note_fields.position.y = 0
			health_bar.position.y = 660
		1:
			note_fields.position.y = 500
			health_bar.position.y = 50

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
	score_text.text  = tr("score", &"gameplay") + ": %s" % (0 if not tally else game.tally.score)
	misses_text.text = tr("misses", &"gameplay") + ": %s" % (0 if not tally else game.tally.misses)

func update_health(health: int) -> void:
	_prev_health = health
	if game is Gameplay: # this system sucks I may change it later
		if game.player and game.player.icon: icon_p1.frame = game.player.icon.get_frame(health)
		if game.enemy and game.enemy.icon: icon_p2.frame = game.enemy.icon.get_frame(100 - health)

func display_judgement(image: Texture2D) -> void:
	combo_group.display_judgement(image)

func display_combo(combo: int = -1) -> void:
	if combo < 5:
		# TODO: miss combo
		return
	combo_group.display_combo(combo)

#func get_rank(accuracy: float) -> String:
#	# score text
#	# str(game.tally).replace("{rank}", get_rank(game.tally.accuracy))
#	match accuracy:
#		# based on Turkey grading system.
#		_ when accuracy >= 100: return "AA" # S+
#		_ when accuracy >= 95: return "BA" # S
#		_ when accuracy >= 90: return "BB" # A+
#		_ when accuracy >= 85: return "CB" # A
#		_ when accuracy >= 80: return "CC" # B+
#		_ when accuracy >= 75: return "DC" # B
#		_ when accuracy >= 70: return "DD" # C+
#		_ when accuracy >= 65: return "FD" # C
#		_ when accuracy <= 60: return "FF" # D
#		_ when accuracy <= -1: return "FAIL" # F, kinda, whatever
#	return "N/A"

func on_beat_hit(_beat: float) -> void:
	if icon_p1: icon_p1.scale = default_ip1_scale * 1.2
	if icon_p2: icon_p2.scale = default_ip2_scale * 1.2

func get_bump_lerp(from: float = 2.0, to: float = 1.0, _delta: float = 0) -> float:
	return lerpf(from, to, 0.05) # TODO: use exp()
func get_bump_lerp_vector(from: Vector2 = Vector2.ONE, to: Vector2 = Vector2.ONE, _delta: float = 0) -> Vector2:
	return Global.lerpv2(from, to, 0.05) # TODO: use exp()
func get_bump_scale() -> float:
	return 0.03
