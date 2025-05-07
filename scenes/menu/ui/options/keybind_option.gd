extends OptionBar

const INSTRUCTIONS: String = "Press TAB while changing to switch to your alternative keybind.

Press BACKSPACE to delete the key.

Press SPACE, ENTER or ESCAPE to stop binding"
const BIG_BAR: String = "————————————————————————————————————————"

@onready var primary_keybind: Label = $"value_group/pri"
@onready var secondary_keybind: Label = $"value_group/sec"
@onready var bind_labels: Array[Label] = [primary_keybind, secondary_keybind]

var prohibited_keys: Array[Key] = [KEY_ESCAPE, KEY_ENTER, KEY_PAUSE, KEY_BACKSPACE, KEY_TAB]
var current_binds: PackedStringArray = []
var original_binds: PackedStringArray = []
var bind_selected: int = 0

func _ready() -> void:
	reset_binds()
	description = INSTRUCTIONS + "\n\n" + BIG_BAR + "\n\n" + description
	super()

func reset_binds() -> void:
	current_binds.clear()
	if variable_name in Global.settings.controls:
		for i: String in Global.settings.controls[variable_name]:
			current_binds.append(i)
	original_binds = current_binds.duplicate()

func _unhandled_input(event: InputEvent) -> void:
	if not changing: return
	if not event.is_echo() and event.pressed:
		var deleting: bool = event.keycode == KEY_BACKSPACE
		var switching: bool = event.keycode == KEY_TAB
		if deleting:
			bind_labels[bind_selected].text = "---"
			current_binds[bind_selected] = ""
		elif switching:
			bind_selected = wrapi(bind_selected + 1, 0, current_binds.size())
			update_hover()
		elif not prohibited_keys.has(event.keycode):
			# TODO: make keybinds swap if they're indentical.
			var key_string: String = OS.get_keycode_string(event.keycode)
			#print_debug("should be ", key_string.to_upper(), ", boss.")
			current_binds[bind_selected] = key_string
			update_value()
			#changing = false

func update_value(_next: int = 0) -> void:
	if not current_binds.is_empty():
		for i: int in bind_labels.size():
			bind_labels[i].text = current_binds[i].to_upper()
			if current_binds[i].dedent().is_empty():
				bind_labels[i].text = "---"
	#bind_selected = 0
	#changing = false
	update_hover()

func update_setting(_next: int = 0) -> void:
	if variable_name in Global.settings.controls:
		Global.settings.controls[variable_name] = current_binds

func update_hover() -> void: # PLACEHOLDER ↓ ↓ ↓ ( I THINK
	for i: int in bind_labels.size():
		var next_color: Color = Color.WHITE
		if i == bind_selected and changing: next_color = Color.CYAN
		bind_labels[i].modulate = next_color

func value_changed() -> bool:
	return current_binds == original_binds
