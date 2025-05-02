@tool class_name OptionBar extends Control

const INACTIVE_COLOR: Color = Color("#b3b3b3")

@onready var name_label: Label = $"name_label"

@onready var value_group: Control = $"value_group"
@onready var value_box: HBoxContainer
@onready var value_bar: ColorRect
@onready var value_label: Label

@export var values: Array = [true, false]
@export var display_name: StringName = &"Setting":
	set(new_dpnm):
		if name_label: name_label.text = new_dpnm
		display_name = new_dpnm
@export var variable_name: StringName
@export_multiline var description: String = "(No description)."
var settings: Settings

var current_value: int = 0
var changing: bool = false

func _ready() -> void:
	if has_node("value_group/value_name"): value_label = get_node("value_group/value_name")
	if has_node("value_group/value_bar"): value_bar = get_node("value_group/value_bar")
	if has_node("value_group/values"): value_box = get_node("value_group/values")
	name_label.text = display_name # safety measure (sometimes it doesn't show)
	if not settings:
		#if Gameplay.current and Gameplay.current.local_settings:
		#	settings = Gameplay.current.local_settings
		#else:
		settings = Global.settings
	if not variable_name.is_empty():
		var setting = settings.get(variable_name)
		match typeof(setting):
			TYPE_INT: current_value = int(setting)
			TYPE_BOOL: current_value = int(not setting)
			_: current_value = values.find(str(setting))
	if value_bar:
		for i: int in values.size():
			var bar: ColorRect = value_bar.duplicate()
			bar.color = INACTIVE_COLOR if current_value != i else Color.WHITE
			value_box.add_child(bar)
		value_bar.hide()
	update_value()

func update_value(next: int = 0) -> void:
	var previous_value: int = current_value
	current_value = wrapi(current_value + next, 0, values.size())
	value_label.text = get_value_string()
	if value_box and previous_value != current_value:
		for i: int in value_box.get_child_count():
			value_box.get_child(i).color = INACTIVE_COLOR if i != current_value else Color.WHITE

func update_setting(next: int = 0) -> void:
	var setting = settings.get(variable_name)
	match typeof(setting):
		TYPE_BOOL: settings.set(variable_name, bool(1 - current_value))
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			var x: int = wrapi(current_value + next, 0, values.size())
			settings.set(variable_name, values[x])
		TYPE_INT: settings.set(variable_name, wrapi(current_value + next, 0, values.size()))

func update_hover() -> void:
	# PLACEHOLDER ↓ ↓ ↓ ( I THINK
	value_group.get_child(1).modulate = Color.CYAN if changing else Color.WHITE
	value_group.get_child(0).modulate = Color.CYAN if changing else Color.WHITE

func get_value_string() -> String:
	return str(values[current_value]).replace("true", "ON").replace("false", "OFF")
