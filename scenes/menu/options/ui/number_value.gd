extends "res://scenes/menu/options/ui/value_bar.gd"

@export var step: float = 0.01

func update_setting(next: int = 0) -> void:
	var setting = settings.get(variable_name)
	match typeof(setting):
		TYPE_BOOL: setting = not setting
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			var x: int = wrapi(current_value + next, 0, values.size())
			setting = values[x]
		TYPE_INT, TYPE_FLOAT:
			var s: float = roundf(step) if typeof(setting) == TYPE_INT else step
			setting = setting + s * next
