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

# TODO: add combo stacking
#@export var combo_stacking: bool = true

var display_digits: Array[Node2D] = []
var display_tweens: Array[Tween] = []
var judgement_tween: Tween
var combo_digits: int = 3
var assets: ChartAssets
var settings: Settings

func _calculate_velocity(velocity: Vector2, accel: Vector2, delta: float) -> Vector2:
	return velocity + accel * delta

func _ready() -> void:
	if not has_node("judgement"):
		add_child(Sprite2D.new()) # Judgement
		get_child(0).set_meta(VELOCITY, Vector2.ZERO)
		get_child(0).set_meta(ACCELERATION, Vector2.ZERO)
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
		settings = Gameplay.current.local_settings
	if not settings: settings = Global.settings

func _process(delta: float) -> void:
	for i: Sprite2D in get_children():
		if not i.visible or i.get_meta(VELOCITY) == null or i.get_meta(ACCELERATION) == null:
			continue
		var veloc: Vector2 = i.get_meta(VELOCITY, Vector2.ZERO)
		var accel: Vector2 = i.get_meta(ACCELERATION, Vector2.ZERO)
		var vdt: Vector2 = 0.5 * _calculate_velocity(veloc, accel, delta) - veloc
		i.position += (vdt * delta) * -1

func display_judgement(judge: String) -> void:
	var judgement: Sprite2D = get_child(0)
	judgement.position = Vector2.ZERO
	judgement.self_modulate.a = 1.0
	judgement.scale = judge_scale #* randf_range(0.9, 1.1)
	judgement.texture = assets.judgement_assets[judge]
	judgement.position.y = -50
	if not settings.simplify_popups:
		judgement.set_meta(ACCELERATION, Vector2(0, 500))
		judgement.set_meta(VELOCITY, Vector2(randi_range(0, 10), randi_range(140, 175)))
	judgement.visible = true
	if judgement_tween: judgement_tween.stop()
	judgement_tween = create_tween().set_parallel(true)
	if judgement.scale != judge_scale:
		judgement_tween.tween_property(judgement, "scale", judge_scale, 0.2)
	judgement_tween.tween_property(judgement, "self_modulate:a", 0.0, 0.4).set_delay(Conductor.crotchet * 0.1)
	judgement_tween.finished.connect(judgement.hide)

func display_combo(amnt: int = 0) -> void:
	hide_digits()
	var combo: String = str(amnt)
	var digits: Array = combo.pad_zeros(combo_digits).split("")
	var offset: float = digits.size() - 3
	for i: int in digits.size():
		if i > display_digits.size() - 1:
			display_tweens.append(null)
			setup_digit(i)
		var num_score: Sprite2D = display_digits[i]
		num_score.frame = int(digits[i])
		num_score.position = Vector2(
			(size.x * 0.5) - (90 * combo_scale.x) * (offset - i) - (combo_digits * 10),
			(size.y * 0.25) + 25
		)
		num_score.scale = combo_scale
		#num_score.scale.x *= 1.5
		num_score.self_modulate.a = 1.0
		if not settings.simplify_popups:
			num_score.set_meta(ACCELERATION, Vector2(0, randi_range(250, 300)))
			num_score.set_meta(VELOCITY, Vector2(randi_range(-5, 5), randi_range(130, 150)))
		num_score.show()
		display_tweens[i] = create_tween().set_parallel(true).bind_node(num_score)
		if num_score.scale != combo_scale:
			display_tweens[i].tween_property(num_score, "scale", combo_scale, 0.1)
		display_tweens[i].tween_property(num_score, "self_modulate:a", 0.0, 0.45).set_delay(Conductor.crotchet * 0.5)
		display_tweens[i].finished.connect(num_score.hide)

func compute_velocity(vel: float, accel: float, delta: float) -> float:
	return vel + accel * (0.0 if accel <= 0.0 else delta)

func is_moving(node: Node) -> bool:
	return node.get_meta(VELOCITY, Vector2.ZERO) != Vector2.ZERO or \
		node.get_meta(ACCELERATION, Vector2.ZERO) != Vector2.ZERO

func setup_digit(digit: int) -> Sprite2D:
	var digit_name: String = "combo_digit%s" % digit
	var sprite: Sprite2D = get_node(digit_name) if has_node(digit_name) else Sprite2D.new()
	sprite.modulate.a = 1.0
	if not sprite.texture:
		sprite.texture = assets.combo_numbers.duplicate()
		sprite.hframes = 10
	sprite.hide()
	display_digits[digit] = sprite
	if not has_node(digit_name): add_child(sprite)
	return sprite

func hide_digits() -> void:
	for i: Tween in display_tweens: if i: i.stop()
	for i: Node2D in display_digits: if i:
		i.set_meta(VELOCITY, Vector2.ZERO)
		i.set_meta(ACCELERATION, Vector2.ZERO)
		i.hide()
