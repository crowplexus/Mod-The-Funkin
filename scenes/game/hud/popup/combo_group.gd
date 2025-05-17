extends Control

const ACCELERATION: String = "acceleration"
const VELOCITY: String = "velocity"

## Minimum amount of digits which should be displayed when hitting combo.[br]
## Keep it as 0 or less for the game to figure out by itself.
## Capped at 16 for *obvious* reasons.
@export var min_digits: int = 0:
	set(nmd): min_digits = clampi(nmd, 0, 16)
## Scale of the judgement sprites, leave it as [code]Vector2.ZERO[/code] for it to depend on the chart assets.
@export var judge_scale: Vector2 = Vector2.ZERO
## Scale of the combo sprites, leave it as [code]Vector2.ZERO[/code] for it to depend on the chart assets.
@export var combo_scale: Vector2 = Vector2.ZERO
## [see]Settings.combo_stacking[/see]
@export var combo_stacking: bool = false

var display_digits: Array[Node2D] = []
var display_tweens: Array[Tween] = []
var judgement_tween: Tween
var combo_digits: int = 3
var assets: ChartAssets

func _ready() -> void:
	if not has_node("judgement"):
		add_child(PhysicsSprite2D.new()) # Judgement
		get_child(0).acceleration = Vector2.ZERO
		get_child(0).velocity = Vector2.ZERO
		get_child(0).name = "judgement"
	if Gameplay.current:
		if Gameplay.current.chart:
			if Gameplay.current.assets:
				assets = Gameplay.current.assets
				if judge_scale == Vector2.ZERO: judge_scale = assets.judgement_scale
				if combo_scale == Vector2.ZERO: combo_scale = assets.combo_scale
			if min_digits <= 0:
				combo_digits = clampi(str(Gameplay.current.chart.note_counts[0]).length(), 1, 5)
			else:
				combo_digits = min_digits	
			display_tweens.resize(5)
			display_digits.resize(5)
			for i: int in display_digits.size():
				setup_digit(i)
	if Global.settings.simplify_popups: combo_stacking = false
	else: combo_stacking = Global.settings.combo_stacking

func display_judgement(judge: String) -> void:
	var popup_judge: PhysicsSprite2D
	if combo_stacking:
		popup_judge = get_child(0).duplicate()
		popup_judge.visible = false
		add_child(popup_judge)
	else:
		popup_judge = get_child(0)
	popup_judge.position = Vector2.ZERO
	popup_judge.modulate.a = 1.0
	popup_judge.scale = judge_scale
	popup_judge.texture_filter = assets.judgement_filter
	popup_judge.texture = assets.judgement_assets[judge]
	popup_judge.position.y = -50
	if not Global.settings.simplify_popups:
		popup_judge.velocity.y = randi_range(140, 175)
		popup_judge.velocity.x = randi_range(0, 10)
		popup_judge.acceleration.y = 550
	else:
		popup_judge.scale *= 1.1
	popup_judge.visible = true
	var tween: Tween
	if not combo_stacking:
		if judgement_tween: judgement_tween.stop()
		judgement_tween = create_tween().set_parallel(true)
		tween = judgement_tween
	else:
		tween = create_tween().set_parallel(true)
	tween.finished.connect(popup_judge.queue_free if combo_stacking else popup_judge.hide)
	if popup_judge.scale != judge_scale:
		tween.tween_property(popup_judge, "scale", judge_scale, 0.2)
	tween.tween_property(popup_judge, "modulate:a", 0.0, 0.4).set_delay(Conductor.crotchet * 0.1)

func display_combo(amnt: int = 0) -> void:
	#hide_digits()
	var combo: String = str(amnt)
	var digits: Array = combo.pad_zeros(combo_digits).split("")
	var offset: float = digits.size() - 3
	for i: int in digits.size():
		if i > display_digits.size() - 1:
			display_tweens.append(null)
			setup_digit(i)
		var num_score: PhysicsSprite2D = get_digit(i)
		num_score.frame = int(digits[i])
		num_score.position = Vector2(
			((size.x * 0.5) - (combo_scale.x * offset - (i * 45))),
			(size.y * 0.25) + (combo_scale.y + 25)
		)
		num_score.scale = combo_scale
		num_score.modulate.a = 1.0
		if not Global.settings.simplify_popups:
			num_score.acceleration.y = randi_range(200, 300)
			num_score.velocity.y = randi_range(140, 160)
			num_score.velocity.x = randf_range(-5, 5)
		else:
			num_score.scale.x *= 1.35
		num_score.texture_filter = assets.combo_filter
		num_score.show()
		var tween: Tween
		if not combo_stacking:
			if display_tweens[i]: display_tweens[i].kill()
			display_tweens[i] = create_tween().set_parallel(true)
			tween = display_tweens[i]
		else:
			tween = create_tween().set_parallel(true)
		tween.finished.connect(num_score.queue_free if combo_stacking else num_score.hide)
		if num_score.scale != combo_scale:
			tween.tween_property(num_score, "scale", combo_scale, 0.1)
		tween.tween_property(num_score, "modulate:a", 0.0, 0.45).set_delay(Conductor.crotchet * 0.5)

func setup_digit(digit: int) -> PhysicsSprite2D:
	var digit_name: String = "combo_digit%s" % digit
	var is_there: bool = has_node(digit_name)
	var sprite: PhysicsSprite2D
	if combo_stacking:
		if is_there and get_node(digit_name).visible == false:
			sprite = get_node(digit_name) as PhysicsSprite2D
		else:
			sprite = PhysicsSprite2D.new()
	else:
		if is_there: sprite = get_node(digit_name) as PhysicsSprite2D
		else: sprite = PhysicsSprite2D.new()
	sprite.modulate.a = 1.0
	if not sprite.texture:
		sprite.texture = assets.combo_numbers.duplicate()
		sprite.hframes = 10
	sprite.hide()
	display_digits[digit] = sprite
	if not has_node(digit_name) or combo_stacking:
		add_child(sprite)
	return sprite

func get_digit(digit: int) -> PhysicsSprite2D:
	if not combo_stacking:
		return display_digits[digit]
	return setup_digit(digit)

func hide_digits() -> void:
	for i: Tween in display_tweens: if i: i.stop()
	for i: PhysicsSprite2D in display_digits: if i:
		i.acceleration = Vector2.ZERO
		i.velocity = Vector2.ZERO
		i.hide()
