extends CanvasLayer

@onready var fps_label: Label = $"%fps_label"
@onready var volume_slider: ProgressBar = $"%volume_slider"
@onready var volume_sound: AudioStreamPlayer = $"%volume_sound"
@onready var update_timer: Timer = $"%update_timer"

var vstwn: Tween
var muted: bool = false
var show_debug: bool = false
var pressed_debug_key: bool = false

func _ready() -> void:
	volume_slider.modulate.a = 0.0
	update_timer.timeout.connect(func() -> void:
		update_overlay()
		update_timer.start(1.0)
	)
	await RenderingServer.frame_post_draw
	fps_label.visible = not Global.settings.hide_fps_info
	pressed_debug_key = Global.settings.hide_fps_info
	update_timer.timeout.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed: return
	match event.keycode:
		KEY_F1:
			if not pressed_debug_key:
				pressed_debug_key = true
				update_overlay()
			fps_label.visible = not fps_label.visible
			Global.settings.hide_fps_info = not fps_label.visible
		KEY_F3 when OS.is_debug_build():
			show_debug = not show_debug
			if not pressed_debug_key:
				pressed_debug_key = true
			update_overlay()

	if event.is_action("volume_up"):
		if Global.settings.master_mute:
			Global.settings.master_mute = false
		update_master_volume(5)
		Global.settings.update_master_volume()
		display_volume_slider()
	if event.is_action("volume_down"):
		if Global.settings.master_mute:
			Global.settings.master_mute = false
		update_master_volume(-5)
		Global.settings.update_master_volume()
		display_volume_slider()
	if event.is_action("volume_mute"):
		Global.settings.master_mute = not Global.settings.master_mute
		Global.settings.update_master_volume()
		display_volume_slider()

func update_overlay() -> void:
	var fps_count: float = Engine.get_frames_per_second()
	if show_debug and OS.is_debug_build(): # I had fun.
		fps_label.text = "————Prototype Build————"
		fps_label.text += "\n%.0f FPS" % fps_count
		fps_label.text += "\nMemory: %s" % String.humanize_size(OS.get_static_memory_usage())
		if is_inside_tree() and get_tree().current_scene:
			fps_label.text += "\n————Current Scene————"
			fps_label.text += "\nName: %s" % get_tree().current_scene.name
			fps_label.text += "\nNodes: %s" % get_tree().root.get_child_count()
		fps_label.text += "\n————Current System————"
		fps_label.text += "\nRunning: %s" % OS.get_distribution_name()
		fps_label.text += "\nProgram Process ID: %s" % OS.get_process_id()
		fps_label.text += "\nLanguage: %s (OS) %s (GAME)" % [ OS.get_locale_language(), Global.settings.language ]
		fps_label.text += "\n——————————————————"
	else:
		fps_label.text = "%.0f FPS" % fps_count
	if OS.is_debug_build() and not pressed_debug_key:
		fps_label.text += "\nF1 TO HIDE\nF3 FOR MORE"

func update_master_volume(bhm: int = 0) -> void:
	Global.settings.master_volume += bhm

func display_volume_slider() -> void:
	if vstwn: vstwn.kill()
	volume_slider.value = Global.settings.master_volume
	if Global.settings.master_mute:
		volume_slider.value = 0
	volume_slider.modulate.a = 1.0
	vstwn = create_tween().set_ease(Tween.EASE_OUT)
	vstwn.tween_property(volume_slider, "modulate:a", 0.0, 0.5).set_delay(0.5)
	volume_sound.play()
	
