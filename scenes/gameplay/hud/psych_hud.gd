extends "res://scenes/gameplay/hud/classic_hud.gd"

const MAX_HISTORY: int = 20

## If the score text should zoom when hitting notes.
@export var zoom_on_hit: bool = true
## Default rating string.
@export var rating_string: String = "?"
## Scale of the score text when zooming.
@export var zoom_scale: Vector2 = Vector2(1.075, 1.075)
var score_text_tween: Tween

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

func init_vars() -> void:
	super()
	score_text.text = "%s: 0 | %s: 0 | %s: ?" % [ tr("score", &"gameplay"), tr("combo_breaks", &"gameplay"), tr("rating") ]

func update_health_bar(_delta: float) -> void:
	if health_bar.value != _prev_health:
		health_bar.value = _prev_health

func update_icons(delta: float) -> void:
	if icon_p1 and icon_p1.scale != default_ip1_scale:
		icon_p1.scale = Global.lerpv2(default_ip1_scale, icon_p1.scale, exp(-delta * 9.0 * Conductor.rate))
		icon_p1.position.x = default_ip1_pos.x + ((health_bar.size.x ) * 0.5) - (_prev_health * 6.0)
	if icon_p2 and icon_p2.scale != default_ip2_scale:
		icon_p2.scale = Global.lerpv2(default_ip2_scale, icon_p2.scale, exp(-delta * 9.0 * Conductor.rate))
		icon_p2.position.x = default_ip2_pos.x + ((health_bar.size.x ) * 0.5) - (_prev_health * 6.0)
	if game is Gameplay: # this system sucks I may change it later
		if game.player and game.player.icon: icon_p1.frame = game.player.icon.get_frame(health_bar.value)
		if game.enemy and game.enemy.icon: icon_p2.frame = game.enemy.icon.get_frame(100 - health_bar.value)

func update_score_text(missed: bool = false) -> void:
	var tally: bool = game and game.tally
	if not tally:
		score_text.text = "%s: 0 | %s: 0 | %s: ?" % [ tr("score", &"gameplay"), tr("combo_breaks", &"gameplay"), tr("rating") ]
		return
	var rating: String = "?"
	_min_score = Tally.calculate_worst_score(game.tally.notes_hit_count, game.tally.misses + game.tally.breaks)
	score_text.text = "%s: {s} | %s: {cb} | %s: {r}" % [ tr("score", &"gameplay"), tr("combo_breaks", &"gameplay"), tr("rating") ]
	var rating_str: String = rating_string
	var max_avg: float = Tally.calculate_perfect_score(game.tally.notes_hit_count)
	var min_avg: float = Tally.calculate_worst_score(game.tally.notes_hit_count, game.tally.misses + game.tally.breaks)
	update_rating(Tally.calculate_score_percentage(game.tally.score, max_avg, min_avg))
	if game.tally.notes_hit_count > 0:
		rating_str = "%s (%.2f%%)" % [ rating_string, average_accuracy ]
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
	var acc: float = clampf(accuracy, 0.0, 100.0) # just in case, sometimes this thing hates me.
	accuracy_history.append(acc)
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
