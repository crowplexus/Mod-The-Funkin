extends CanvasLayer

@onready var fps_label: Label = $"%fps_label"
@onready var update_timer: Timer = $"%update_timer"
var muted: bool = false

func _ready() -> void:
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
		KEY_MINUS, KEY_KP_SUBTRACT:
			if Global.settings.master_mute:
				Global.settings.master_mute = false
			update_master_volume(-5)
			Global.settings.update_master_volume()
		KEY_0, KEY_KP_0:
			Global.settings.master_mute = not Global.settings.master_mute
			Global.settings.update_master_volume()

func update_overlay() -> void:
	fps_label.text = "%s FPS | " % Engine.get_frames_per_second()
	if OS.is_debug_build():
		fps_label.text += "%s RAM" % String.humanize_size(OS.get_static_memory_usage())

func update_master_volume(bhm: int = 0) -> void:
	Global.settings.master_volume += bhm
