@tool class_name OptionItem extends Resource

enum Type { BOOL, INT, FLOAT, ENUM, LINK }

#@export_category("General")
@export var name: String
@export var setting: String
@export_multiline var description: String = ""
@export var link_url: String = ""

#@export_category("Numeric Options")
@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var num_step : float = 1.0
@export var type: Type = Type.BOOL

#@export_category("Enumerator Options")
@export var values: PackedStringArray = [] # that's... that's it, welcome.

var current_value: Variant: # just in case.
	get: return Global.settings.get(setting)
	set(new_value): Global.settings.set(setting, new_value)

func change(p_next: int = 0) -> void:
	var new_value: Variant = null
	match type:
		OptionItem.Type.BOOL when p_next != 0: new_value = not current_value
		OptionItem.Type.INT, OptionItem.Type.FLOAT:
			var is_shift: bool = Input.is_key_label_pressed(KEY_SHIFT)
			new_value = wrap(current_value + (p_next * (num_step * 4.0 if is_shift else num_step)), min_value, max_value + 1.0)
		OptionItem.Type.ENUM:
			if current_value is int:
				new_value = wrapi(current_value + p_next, 0, values.size())
			else:
				var current_index: int = values.find(current_value)
				if current_index == -1:  # Fallback if value missing
					current_index = 0
				new_value = values[wrapi(current_index + p_next, 0, values.size())]
	current_value = new_value

func _validate_type(p_type: int) -> void:
	match p_type:
		TYPE_INT, TYPE_FLOAT:
			if type == TYPE_INT: type = Type.INT
			else: type = Type.FLOAT
		_: # default type
			type = Type.BOOL

func _validate_property(property: Dictionary) -> void:
	# Hide irrelevant properties based on type OHHH I LOVE WORKAROUNDS.
	match type:
		Type.BOOL: if property.name in ["min_value", "max_value", "num_step", "values", "link_url"]: property.usage = PROPERTY_USAGE_NO_EDITOR
		Type.INT, Type.FLOAT: if property.name == ["values", "link_url"]: property.usage = PROPERTY_USAGE_NO_EDITOR
		Type.ENUM: if property.name in ["min_value", "max_value", "num_step", "link_url"]: property.usage = PROPERTY_USAGE_NO_EDITOR
		Type.LINK: if property.name in ["setting", "min_value", "max_value", "num_step", "values"]: property.usage = PROPERTY_USAGE_NO_EDITOR
		_: if property.name in ["min_value", "max_value", "num_step", "values", "link_url"]: property.usage = PROPERTY_USAGE_NO_EDITOR
