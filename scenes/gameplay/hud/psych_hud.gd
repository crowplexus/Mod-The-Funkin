extends "res://scenes/gameplay/hud/classic_hud.gd"

const MAX_HISTORY: int = 20

@onready var time_bar: ProgressBar = $"time_bar"
@onready var time_text: Label = $"time_bar/time_text"

## If the score text should zoom when hitting notes.
@export var zoom_on_hit: bool = true
## Default rating string.
@export var rating_string: String = "?"
var _rating_string_default: String = rating_string
## Scale of the score text when zooming.
@export var zoom_scale: Vector2 = Vector2(1.075, 1.075)
var score_text_tween: Tween
var timer_tween: Tween

var rating_array: Array = [
	["AA", 100], # Perfect
	["BA", 90], # Sick! / Excellent
	["BB", 85], # Great
	["CB", 80], # Good
	["CC", 75], # Bruh / Above Average
	["DC", 70], # Bad / Average
	["DD", 65], # Shit / Passing
	["FD", 60], # You Suck! / Marginal Fail
	["FF", 0], # Fail
]
# For averaging the value of accuracy
var accuracy_history: Array[float] = []
var average_accuracy: float = 0.0
var settings: Settings

func _ready() -> void:
	settings = Gameplay.current.local_settings if Gameplay.current else Global.settings
	super()

func init_vars() -> void:
	time_bar.modulate.a = 0.0
	combo_group.position.y -= 60
	if settings.timer_style > 0:
		if timer_tween: timer_tween.kill()
		timer_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
		timer_tween.tween_property(time_bar, "modulate:a", 1.0, 0.5).set_delay(Conductor.crotchet)
	rating_string = _rating_string_default
	super()

func settings_changed(s: Settings = Global.settings) -> void:
	if not s: return
	match s.scroll:
		0:
			if Gameplay.current and Gameplay.current.strumlines:
				Gameplay.current.strumlines.position.y = 0
			health_bar.position.y = 660
			time_bar.position.y = 19
		1:
			if Gameplay.current and Gameplay.current.strumlines:
				Gameplay.current.strumlines.position.y = 510
			health_bar.position.y = 65
			time_bar.position.y = 693
	health_bar.self_modulate.a = settings.health_bar_alpha * 0.01
	icon_p1.self_modulate.a = settings.health_bar_alpha * 0.01
	icon_p2.self_modulate.a = settings.health_bar_alpha * 0.01
	match s.timer_style:
		0: time_bar.modulate.a = 0.0
		1, 2:
			if time_text.get_theme_font_size("font_size") != 32:
				time_text.add_theme_font_size_override("font_size", 32)
		3: # Song Name text is bigger for some reason
			if time_text.get_theme_font_size("font_size") != 24:
				time_text.add_theme_font_size_override("font_size", 24)
	if s.timer_style > 0 and time_bar.modulate.a <= 0.0:
		if timer_tween: timer_tween.kill()
		timer_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
		timer_tween.tween_property(time_bar, "modulate:a", 1.0, 0.5).set_delay(Conductor.crotchet)

func _process(delta: float) -> void:
	super(delta)
	if time_bar.visible and time_bar.modulate.a > 0.0:
		update_time_text()

func update_health_bar(_delta: float) -> void:
	if health_bar.value != _prev_health:
		health_bar.value = _prev_health

func update_icons(delta: float) -> void:
	if icon_p1 and icon_p1.scale != default_ip1_scale:
		icon_p1.scale = lerp(default_ip1_scale, icon_p1.scale, exp(-delta * icon_zoom_mult * Conductor.rate))
		icon_p1.position.x = default_ip1_pos.x + ((health_bar.size.x * default_ip1_scale.x) * 0.5) - (_prev_health * 6.0)
	if icon_p2 and icon_p2.scale != default_ip2_scale:
		icon_p2.scale = lerp(default_ip2_scale, icon_p2.scale, exp(-delta * icon_zoom_mult * Conductor.rate))
		icon_p2.position.x = default_ip2_pos.x + ((health_bar.size.x * default_ip2_scale.x) * 0.5) - (_prev_health * 6.0)
	if game is Gameplay: # this system sucks I may change it later
		if game.player and game.player.icon: icon_p1.frame = game.player.icon.get_frame(health_bar.value)
		if game.enemy and game.enemy.icon: icon_p2.frame = game.enemy.icon.get_frame(100 - health_bar.value)

func update_score_text(missed: bool = false) -> void:
	var tally: bool = game and game.tally
	if not tally:
		score_text.text = "%s: 0 | %s: 0 | %s: ?" % [ tr("score", &"gameplay"), tr("combo_breaks", &"gameplay"), tr("rating") ]
		return
	_min_score = Tally.calculate_worst_score(game.tally.notes_hit_count, game.tally.misses + game.tally.breaks)
	score_text.text = "%s: {s} | %s: {cb} | %s: {r}" % [ tr("score", &"gameplay"), tr("combo_breaks", &"gameplay"), tr("rating") ]
	var misses: int = game.tally.misses + game.tally.breaks
	var rating_str: String = rating_string
	var max_avg: float = Tally.calculate_perfect_score(game.tally.notes_hit_count)
	var min_avg: float = Tally.calculate_worst_score(game.tally.notes_hit_count, misses)
	@warning_ignore("narrowing_conversion") # actually shut the fuck up.
	update_rating(Tally.calculate_score_percentage(game.tally.score, max_avg, min_avg))
	if game.tally.notes_hit_count > 0:
		rating_str = "%s (%.2f%%)" % [ rating_string, average_accuracy ]
		if misses < 10:
			var clear_flag: String = game.tally.get_clear_flag()
			if not clear_flag.is_empty() and clear_flag != "NOPLAY":
				rating_str += " - " + clear_flag
		else:
			rating_str += " - Clear"
	score_text.text = score_text.text.replace("{s}", str(game.tally.score)) \
		.replace("{cb}", str(game.tally.misses + game.tally.breaks)) \
		.replace("{r}", rating_str)
	if zoom_on_hit and not missed:
		score_text.pivot_offset = score_text.size * 0.5
		score_text.scale = zoom_scale
		if score_text_tween: score_text_tween.kill()
		score_text_tween = create_tween()
		score_text_tween.tween_property(score_text, "scale", Vector2.ONE, 0.2)

func update_rating(accuracy: float) -> void:
	accuracy_history.append(clampf(accuracy, 0.0, 100.0))
	if accuracy_history.size() > MAX_HISTORY:
		accuracy_history.pop_front()

	average_accuracy = 0.0
	if not accuracy_history.is_empty():
		average_accuracy = accuracy_history.reduce(func(acc: float, val: float) -> float: return acc + val) / accuracy_history.size()

	var best_threshold: float = 0.0
	for rating in rating_array:
		if rating[1] <= average_accuracy and rating[1] >= best_threshold:
			rating_string = rating[0]
			best_threshold = rating[1]
			break

func update_time_text() -> void:
	if not time_bar.visible or time_bar.modulate.a <= 0.0:
		return
	var calc: float = clampf(Conductor.time / Conductor.length, 0.0, Conductor.length)
	var time: float = clampf(Conductor.time, 0.0, Conductor.length)
	time_bar.value = calc * time_bar.max_value
	match settings.timer_style:
		1: # Time Left
			time_text.text = "%s" % Global.format_to_time(absf(time - Conductor.length))
		2: # Time Elapsed
			time_text.text = "%s" % Global.format_to_time(time)
		3: # Song Name
			time_text.text = "%s" % Gameplay.chart.name
		4: # Elapsed / Total
			time_text.text = "%s / %s" % [ Global.format_to_time(time), Global.format_to_time(Conductor.length) ]
