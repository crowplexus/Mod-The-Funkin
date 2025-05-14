extends Control

# TAB = Switches keybind ID, escape/enter make you stop binding, pause break is a debug key, backspace is the delete key for the bind.
const PROHIBITED_KEYS: Array[Key] = [KEY_ESCAPE, KEY_ENTER, KEY_PAUSE, KEY_BACKSPACE, KEY_TAB, KEY_META]

@onready var template_label: RichTextLabel = $"binds_label".duplicate()
@onready var controls_list: VBoxContainer = $"controls_list"
@export var controls: Array[String] = [
	"note_left", "note_down", "note_up", "note_right",
	"volume_up", "volume_down", "volume_mute"
]
var labels: Array[RichTextLabel] = []
var binding: bool = false
var can_control: bool = true
var bind_selected: int = 0
var selected: int = 0

func _ready() -> void:
	$"binds_label".queue_free()
	for i: int in controls.size(): # I was gonna use a single RichTextLabel but i gave up.
		var control_label: RichTextLabel = template_label.duplicate()
		controls_list.add_child(control_label)
		control_label.modulate.a = 0.6
	change_selection()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not can_control:
		return
	if not binding:
		var move_axis: int = int(Input.get_axis("ui_up", "ui_down"))
		if move_axis  != 0: change_selection(move_axis)
		if Input.is_action_just_pressed("ui_accept"):	
			controls_list.get_child(selected).bbcode_text = ">> %s: BINDING ID %s ([color=yellow]TAB[/color]) <<" % [ controls[selected].replace("_", " ").to_upper(), bind_selected ]
			binding = true
		if Input.is_action_just_pressed("ui_cancel"):
			exit()
	elif event.is_pressed():
		var con: String = controls[selected]
		if event.keycode == KEY_TAB:
			bind_selected = (bind_selected + 1) % Global.settings.controls[con].size()
			controls_list.get_child(selected).bbcode_text = ">>%s: BINDING ID %s ([color=yellow]TAB[/color]) <<" % [
				con.replace("_", " ").to_upper(), bind_selected
			]
		if event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE:
			controls_list.get_child(selected).bbcode_text = "%s: %s" % [ con.replace("_", " ").to_upper(), get_control_str(selected) ]
			binding = false
		if not PROHIBITED_KEYS.has(event.keycode):
			Global.settings.controls[con][bind_selected] = OS.get_keycode_string(event.keycode)
			binding = false
			update_selected_key()

func change_selection(next: int = 0) -> void:
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	selected = wrapi(selected + next, 0, controls.size())
	update_selected_key()

func update_selected_key() -> void:
	for i: int in controls_list.get_child_count():
		var label: RichTextLabel = controls_list.get_child(i)
		var base_text: String = controls[i].replace("_", " ").to_upper()
		var value_text: String = ": " + get_control_str(i)
		if i == selected:
			label.bbcode_text = "> %s%s <" % [base_text, value_text]
			label.modulate.a = 1.0
		else:
			label.bbcode_text = "%s%s" % [base_text, value_text]
			label.modulate.a = 0.6

func exit() -> void:
	can_control = false
	create_tween().set_ease(Tween.EASE_OUT).tween_property(self, "modulate:a", 0.0, 0.5).finished.connect(queue_free)

func get_control_str(i: int) -> String:
	return ", ".join(Global.settings.controls.get(controls[i], [])).to_upper()
