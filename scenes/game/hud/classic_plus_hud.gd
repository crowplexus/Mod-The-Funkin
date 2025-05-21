extends "res://scenes/game/hud/classic_hud.gd"
const MISSED_COLOR: Color = Color("#ca80ff")
@onready var judge_counter: RichTextLabel = $"judgement_counter"

func _rgb_str(color: Color) -> String:
	return "#%02x%02x%02x" % [color.r8, color.g8, color.b8]

func update_score_text(_missed: bool = false) -> void:
	if Gameplay.current and Gameplay.current.player_botplay:
		score_text.text = "BotPlay Enabled"
		return
	var tally: bool = game and game.tally
	var layout: String = "| %s:{scr}/{max} %s:{cbs} |" % [
		tr("score", &"gameplay"), tr("breaks", &"gameplay")
	]
	if not tally:
		score_text.text  = layout.replace("{scr}", "0") \
		.replace("{cbs}", "0") \
		.replace("{acc}", "0%")
		return
	score_text.text  = layout.replace("{scr}", Global.separate_thousands(game.tally.score)) \
		.replace("{cbs}", str(game.tally.misses + game.tally.breaks)) \
		.replace("{max}", Global.separate_thousands(_max_score))
	update_judgement_counter()

func update_judgement_counter() -> void:
	# this sucks
	if not game or not game.tally or not judge_counter.visible: return
	judge_counter.text = ""
	for i: Judgement in Gameplay.current.judgements.list:
		var idx: int = Gameplay.current.judgements.list.find(i)
		if idx == 0 and not Tally.use_epics: continue
		var hits: int = game.tally.tiers_scored[idx]
		judge_counter.text += "[color="+_rgb_str(i.color)+"]"+i.name+":[/color] " + str(hits) + "\n"
	judge_counter.text += "[color="+_rgb_str(MISSED_COLOR)+"]Missed:[/color] " + str(game.tally.misses)
