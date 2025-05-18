@tool class_name CategoryOptions extends Resource

@export var options: Array[OptionItem] = []

func _init(p_options:Array[OptionItem] = []) -> void:
	options = p_options

#func _get_property_list() -> Array:
#	var properties: Array = []
#	for i: int in options.size():
#		properties.append({
#			"name": "options/%d" % i,
#			"type": TYPE_OBJECT,
#			"hint": PROPERTY_HINT_RESOURCE_TYPE,
#			"hint_string": "Option"
#		})
#	return properties

func get_value(setting: String) -> Variant:
	return Global.settings.get(setting)

func set_value(setting: String, value: Variant) -> Variant:
	Global.settings.set(setting, value)
	return get_value(setting)

func append(option: OptionItem) -> OptionItem:
	options.append(option)
	return option

func remove_at(index: int) -> OptionItem:
	var true_index: int = options.find(index)
	if true_index == -1: return null
	var item: OptionItem = options[true_index]
	options.remove_at(index)
	return item

func sort() -> void: return options.sort()
func sort_custom(callable: Callable) -> void: return options.sort_custom(callable)
