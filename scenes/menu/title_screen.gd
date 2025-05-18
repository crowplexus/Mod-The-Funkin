extends Node2D

@onready var cool_text: Label = $"background/cool_text"
@onready var flash_sprite: ColorRect = $"color_rect"
@onready var ng_sprite: Sprite2D = $"newgrounds_sprite"

@onready var confirm_label: Label = $"title_sprites/confirm_label"
@onready var logo_bump: AnimatedSprite2D = $"title_sprites/logo"
@onready var title_sprites: Control = $"title_sprites"

static var skipped_intro: bool = false
var random_text: PackedStringArray
var pressed_enter: bool = false

var enter_text_colors: Array[Color] = [
	Color(0.2, 1.0, 1.0), Color(0.2, 0.2, 0.8)
]
var enter_text_mod_a: Array[float] = [1, .64]
var enter_text_timer: float = 0.0

var flash_tween: Tween

func _ready() -> void:
	title_sprites.hide()
	random_text = get_random_text()
	AudioServer.set_bus_effect_enabled(1, 0, false)
	RenderingServer.set_default_clear_color(Color.BLACK)
	if Global.DEFAULT_SONG and not Conductor.is_music_playing():
		Conductor.bpm = Global.DEFAULT_SONG.bpm
		Conductor.set_music_stream(Global.DEFAULT_SONG)
		Conductor.play_music(0.0, 0.01)
		Global.request_audio_fade(Conductor.bound_music, 0.7, 1.5)
	if skipped_intro: skip_intro()
	Conductor.on_beat_hit.connect(on_beat_hit)

func _process(_delta: float) -> void:
	if Conductor.is_music_playing():
		if ng_sprite.visible and fmod(Conductor.current_beat, 0.1) < 0.01:
			ng_sprite.frame = int(not ng_sprite.frame)
	if confirm_label:
		var speed: float = 0.5 if not pressed_enter else 50.0
		enter_text_timer += _delta * speed
		var timer: float = abs(sin(enter_text_timer * PI))
		if not pressed_enter:
			var interpolated_color: Color = enter_text_colors[0].lerp(enter_text_colors[1], timer)
			confirm_label.add_theme_color_override("font_outline_color", interpolated_color)
			confirm_label.add_theme_color_override("font_color", interpolated_color.darkened(0.6))
		else:
			confirm_label.add_theme_color_override("font_color", Color.WHITE)
			confirm_label.add_theme_color_override("font_outline_color", Color.WHITE)
		confirm_label.modulate.a = lerp(enter_text_mod_a[0], enter_text_mod_a[1], timer)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_echo() and event.is_action("ui_accept"):
		if not skipped_intro:
			skip_intro()
		elif not pressed_enter:
			flash_screen(0.5)
			pressed_enter = true
			Global.play_sfx(Global.resources.get_resource("confirm"))
			await get_tree().create_timer(1.0).timeout
			Global.change_scene("uid://c6hgxbdiwb6yn")

func _exit_tree() -> void:
	Conductor.on_beat_hit.disconnect(on_beat_hit)

func on_beat_hit(beat: float) -> void:
	if skipped_intro:
		logo_bump.frame = 0
		logo_bump.play("logo bumpin")
		return
	match floori(beat):
		0: display_cool_text("The Funkin' Crew Inc.")
		2: add_cool_text("presents")
		3: delete_cool_text()
		4: display_cool_text("In association with")
		6: add_cool_text("newgrounds")
		7: delete_cool_text()
		8: display_cool_text(random_text[0])
		10: add_cool_text(random_text[1])
		11: delete_cool_text()
		12: display_cool_text("Friday")
		13: add_cool_text("Night\n")
		14: add_cool_text("Funkin'")
		15: skip_intro()

func skip_intro() -> void:
	flash_screen()
	delete_cool_text()
	title_sprites.show()
	cool_text.hide()
	await get_tree().create_timer(0.1).timeout
	skipped_intro = true

func flash_screen(duration: float = 4.0) -> void:
	flash_sprite.show()
	flash_sprite.modulate.a = 1.0
	if flash_tween: flash_tween.kill()
	flash_tween = create_tween()
	flash_tween.tween_property(flash_sprite, "modulate:a", 0.0, duration) \
	.finished.connect(flash_sprite.hide)

func display_cool_text(text: String) -> void:
	cool_text.text = text + "\n"
	if ng_sprite.visible: ng_sprite.hide()

func add_cool_text(text: String) -> void:
	cool_text.text += text
	if text == "newgrounds": ng_sprite.show()

func delete_cool_text() -> void:
	if ng_sprite.visible: ng_sprite.hide()
	cool_text.text = ""

func get_random_text() -> PackedStringArray:
	var rt: PackedStringArray = []
	var itp: String = "res://assets/resources/introText.txt"
	var intro_texts: String = FileAccess.open(itp, FileAccess.READ).get_as_text()
	if intro_texts:
		var lines: PackedStringArray = intro_texts.split("\n")
		var i: int = randi_range(0, lines.size()-1)
		var split: PackedStringArray = lines[i].split("--")
		if split.size() >= 2: rt = split
		else: rt = "swagshit--moneymoney".split("--")
	else:
		print_debug("file not found")
		rt = "swagshit--moneymoney".split("--")
	return rt
