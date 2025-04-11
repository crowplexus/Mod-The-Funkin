@tool extends OptionBar

@onready var progress: ProgressBar = $"value_group/progress"

@export var minv: float = 0.0 ## Minimum value the option is allowed to get to.
@export var maxv: float = 1.0 ## Maximum value the option is allowed to get to.
@export var step: float = 0.01 ## blah blah blah.

@export var format_string: String = "%s" ## Format string for the value, useful for percentages.
@export var string_suffix: String = "" ## Suffix that shows after the value.

var _shift_mult: float = 1.0
var _internal_value: Variant = null

func _ready() -> void:
	super()
	_internal_value = settings.get(variable_name)
	progress.min_value = minv
	progress.max_value = maxv
	update_value()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		if event.keycode == KEY_SHIFT:
			_shift_mult = 4.0
	else:
		_shift_mult = 1.0

func update_value(next: int = 0) -> void:
	if typeof(_internal_value) == TYPE_INT or typeof(_internal_value) == TYPE_FLOAT:
		var s: float = round(step) if typeof(_internal_value) == TYPE_INT else step
		_internal_value = wrap(_internal_value + s * (next * _shift_mult), minv, maxv + 1)
		progress.value = _internal_value
	value_label.text = (format_string % str(progress.value)) + string_suffix

func update_setting(next: int = 0) -> void:
	var setting = settings.get(variable_name)
	match typeof(setting):
		TYPE_BOOL: settings.set(variable_name, not setting)
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			var x: int = wrap(current_value + (next * _shift_mult), 0, values.size())
			settings.set(variable_name, values[x])
		TYPE_INT, TYPE_FLOAT:
			var s: float = round(step) if typeof(setting) == TYPE_INT else step
			settings.set(variable_name, wrap(setting + s * (next * _shift_mult), minv, maxv + 1))
