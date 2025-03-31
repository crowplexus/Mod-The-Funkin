@tool extends Control

const INACTIVE_COLOR: Color = Color("#b3b3b3")

@onready var name_label: Label = $"name_label"

@onready var value_label: Label = $"value_group/value_name"
@onready var value_bar: ColorRect = $"value_group/value_bar"
@onready var value_box: HBoxContainer = $"value_group/values"

@export var values: Array = [true, false]
@export var display_name: StringName = &"Setting":
	set(new_dpnm):
		if name_label: name_label.text = new_dpnm
		display_name = new_dpnm
@export var variable_name: StringName
var settings: Settings

var current_value: int = 0

func _ready() -> void:
	name_label.text = display_name # safety measure (sometimes it doesn't show)
	if not settings:
		if get_tree().current_scene and get_tree().current_scene is Gameplay:
			settings = get_tree().current_scene.local_settings
		else:
			settings = Global.settings
	if not variable_name.is_empty():
		var setting = settings.get(variable_name)
		match typeof(setting):
			TYPE_INT, TYPE_BOOL: current_value = int(setting)
			_: current_value = values.find(str(setting))
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
	if previous_value != current_value:
		for i: int in value_box.get_child_count():
			value_box.get_child(i).color = INACTIVE_COLOR if i != current_value else Color.WHITE

func update_setting(next: int = 0) -> void:
	var setting = settings.get(variable_name)
	match typeof(setting):
		TYPE_BOOL: setting = not setting
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			var x: int = wrapi(current_value + next, 0, values.size())
			setting = values[x]
		TYPE_INT: setting = wrapi(current_value + next, 0, values.size())

func get_value_string() -> String:
	return str(values[current_value]).replace("true", "ON").replace("false", "OFF")
