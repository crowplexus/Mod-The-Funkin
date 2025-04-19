extends CanvasLayer

@onready var fps_label: Label = $"%fps_label"
@onready var volume_slider: ProgressBar = $"%volume_slider"
@onready var volume_sound: AudioStreamPlayer = $"%volume_sound"
@onready var update_timer: Timer = $"%update_timer"

var vstwn: Tween
var muted: bool = false

func _ready() -> void:
	volume_slider.modulate.a = 0.0
	update_timer.timeout.connect(func() -> void:
		update_overlay()
		update_timer.start(1.0)
	)
	update_timer.timeout.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed: return
	match event.keycode:
		KEY_EQUAL, KEY_KP_MULTIPLY:
			if Global.settings.master_mute:
				Global.settings.master_mute = false
			update_master_volume(5)
			Global.settings.update_master_volume()
			display_volume_slider()
		KEY_MINUS, KEY_KP_SUBTRACT:
			if Global.settings.master_mute:
				Global.settings.master_mute = false
			update_master_volume(-5)
			Global.settings.update_master_volume()
			display_volume_slider()
		KEY_0, KEY_KP_0:
			Global.settings.master_mute = not Global.settings.master_mute
			Global.settings.update_master_volume()

func update_overlay() -> void:
	fps_label.text = "%s FPS | " % Engine.get_frames_per_second()
	if OS.is_debug_build():
		fps_label.text += "%s RAM" % String.humanize_size(OS.get_static_memory_usage())

func update_master_volume(bhm: int = 0) -> void:
	Global.settings.master_volume += bhm

func display_volume_slider() -> void:
	if vstwn: vstwn.kill()
	volume_slider.value = Global.settings.master_volume
	volume_slider.modulate.a = 1.0
	vstwn = create_tween().set_ease(Tween.EASE_OUT)
	vstwn.tween_property(volume_slider, "modulate:a", 0.0, 0.5).set_delay(0.5)
	volume_sound.play()
	
