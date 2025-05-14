extends Node2D

var credits_thing: PackedScene = load("uid://wh2umjjgf2f6")

@onready var camera: Camera2D = $"camera_2d"
@onready var bg: Sprite2D = $"bg_scroll/background"

@onready var hud: CanvasLayer = $"canvas_layer"
@onready var button_options: BoxContainer = $"canvas_layer/ui/buttons"
@onready var copyright_text: Label = $"canvas_layer/ui/color_rect/copyright_text"
@onready var copyright_rect: ColorRect = $"canvas_layer/ui/color_rect"
@onready var bg_pos: Vector2 = bg.position

static var saw_copyright: bool = false
var buttons: Array[CanvasItem] = []
var moving_copyright: bool = OS.is_debug_build()
var can_input: bool = true

var selected: int = 0
var copyright_tween: Tween

func _ready() -> void:
	for i: CanvasItem in button_options.get_children():
		if i.visible: buttons.append(i)
	if Global.DEFAULT_SONG and not Conductor.is_music_playing():
		Conductor.set_music_stream(Global.DEFAULT_SONG)
		Conductor.bpm = Global.DEFAULT_SONG.bpm
		Conductor.play_music(0.0, 0.7)
	
	if not saw_copyright:
		var start_moving: Callable = func() -> void:
			if not moving_copyright:
				await get_tree().create_timer(1.0).timeout
				moving_copyright = true
		var pos_y: float = copyright_rect.position.y
		copyright_tween = create_tween().set_ease(Tween.EASE_IN)
		copyright_tween.tween_property(copyright_rect, "position:y", pos_y + 60, 0.5).set_delay(0.5)
		copyright_tween.finished.connect(start_moving)
	
	change_selection()

func _process(delta: float) -> void:
	if moving_copyright:
		copyright_text.position.x -= delta * 100
		if copyright_text.position.x < -copyright_text.size.x - 50:
			var pos_y: float = copyright_rect.position.y
			if copyright_tween: copyright_tween.kill()
			copyright_tween = create_tween().set_ease(Tween.EASE_OUT)
			copyright_tween.tween_property(copyright_rect, "position:y", pos_y - 60, 0.6)
			moving_copyright = false
			saw_copyright = true

func _unhandled_input(event: InputEvent) -> void:
	if can_input and not event.is_echo():
		var item_axis: int = int(Input.get_axis("ui_up", "ui_down"))
		if item_axis != 0: change_selection(item_axis)
		if Input.is_action_just_pressed("ui_accept"):
			can_input = false
			confirm_selection()
		if Input.is_action_just_pressed("ui_cancel"):
			can_input = false
			Global.change_scene("uid://ce22u68qyw5bs")

func change_selection(next: int = 0) -> void:
	var ps: AnimatedSprite2D = buttons[selected]
	if ps: ps.play("%s idle" % ps.name)
	selected = wrapi(selected + next, 0, buttons.size())
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	ps = buttons[selected]
	if ps: ps.play("%s selected" % ps.name)
	camera.position.y = ps.global_position.y

func confirm_selection() -> void:
	var ps: = buttons[selected]
	Global.begin_flicker(bg, 0.6, 0.1)
	Global.begin_flicker(ps, 0.6, 0.06)
	Global.play_sfx(Global.resources.get_resource("confirm"))
	for button: CanvasItem in buttons:
		if button.get_index() != selected:
			create_tween().set_ease(Tween.EASE_IN).tween_property(button, "modulate:a", 0.0, 0.6)
	await get_tree().create_timer(0.7).timeout
	match ps.name:
		"storymode":
			saw_copyright = true
			Global.change_scene("uid://dakw6tmvuvou7")
		"freeplay":
			saw_copyright = true
			Global.change_scene("uid://c5qnedjs8xhcw")
		"options":
			saw_copyright = true
			Global.change_scene("uid://btno3m7xritu5")
		"credits":
			can_input = false
			var display_credits: Control = credits_thing.instantiate()
			hud.add_child(display_credits)
			display_credits.label.position = get_viewport_rect().size * 0.005
			display_credits.size = get_viewport_rect().size
			display_credits.z_index = 500 # good enough.
			await display_credits.tree_exited
			can_input = true
			default_confirm()
		_:
			default_confirm()

func default_confirm() -> void:
	bg.show()
	buttons[selected].modulate.a = 0.0
	buttons[selected].show()
	can_input = true
	for button: CanvasItem in buttons:
		create_tween().set_ease(Tween.EASE_IN).tween_property(button, "modulate:a", 1.0, 0.6)
