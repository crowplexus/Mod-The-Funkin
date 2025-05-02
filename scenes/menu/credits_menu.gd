extends Control

# this was made just as a test
# might replace this with an about page in the options menu instead.

@export var credits: Array[PackedStringArray] = []
@onready var bgm: AudioStreamPlayer = $"music"
@onready var label: Label = $"label"

var index: int = 0
var label_tween: Tween
var ended: bool = false
var og_vol: float = 1.0
var og_pos: float = 0.0

func _ready() -> void:
	advance()
	if Global.bgm.playing:
		og_vol = Global.bgm.volume_linear
		Global.request_audio_fade(Global.bgm, 0.0, 1.0)
		await Global.music_fade_tween.finished
		og_pos = Global.bgm.get_playback_position()
		Global.bgm.stop()
	Conductor.bpm = bgm.stream.bpm
	bgm.stream.loop = true
	bgm.play()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_echo() and not ended:
		var scroll_axis: int = int(Input.get_axis("ui_left", "ui_right"))
		if scroll_axis != 0: advance(scroll_axis)
		if event.is_action("ui_cancel") and not ended:
			ended = true
			var tween: Tween = create_tween().set_ease(Tween.EASE_OUT)
			Global.play_sfx(Global.resources.get_resource("cancel"))
			tween.tween_property(self, "modulate:a", 0.0, 0.5)
			await restore_audio()
			queue_free()

func advance(next: int = 0) -> void:
	index = wrapi(index + next, 0, credits.size())
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	label.modulate.a = 0.0
	if label_tween: label_tween.kill()
	label_tween = create_tween().set_ease(Tween.EASE_IN)
	label_tween.tween_property(label, "modulate:a", 1.0, 0.35)
	var credit: PackedStringArray = credits[index]
	label.text = "< %s >\n%s" % [ credit[0], credit[1] ]

func restore_audio(duration: float = 1.0) -> void:
	Global.request_audio_fade(bgm, 0.0, duration)
	await Global.music_fade_tween.finished
	Conductor.bpm = Global.bgm.stream.bpm
	Global.request_audio_fade(Global.bgm, og_vol, 0.5)
	Global.bgm.play(og_pos)
