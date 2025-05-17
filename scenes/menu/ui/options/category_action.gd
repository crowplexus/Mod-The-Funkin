# hacky workaround class for categories that execute functions.
# yes that's why the spacing sucks, i just didn't care.
@tool class_name CategoryAction extends CategoryOptions
enum Type { OPEN_SUBMENU, SCENE_CHANGE, SCENE_REWIND, CUSTOM_FUNCTION }
@export var action_type: Type = Type.OPEN_SUBMENU
@export var submenu_path: String = ""  # For OPEN_SUBMENU
@export var scene_path: String = ""    # For SCENE_CHANGE
@export var custom_function: String = "" # Name of function to call
@export var skip_transition: bool = false # For SCENE_CHANGE

func _init(p_action: Type = Type.OPEN_SUBMENU, p_custom_function: String = "", p_submenu_path: String = "", p_scene_path: String = "", p_skip_transition: bool = false) -> void:
	action_type = p_action
	submenu_path = p_submenu_path
	scene_path = p_scene_path
	custom_function = p_custom_function
	skip_transition = p_skip_transition

func execute_func(target_node: Node) -> void:
	match action_type:
		Type.OPEN_SUBMENU when not submenu_path.is_empty():
			target_node.open_submenu(submenu_path)
		Type.SCENE_CHANGE when not scene_path.is_empty():
			if scene_path == Global.previous_scene_path:
				Global.rewind_scene(skip_transition)
			else:
				Global.change_scene(scene_path, skip_transition)
		Type.SCENE_REWIND:
			Global.rewind_scene(skip_transition)
		Type.CUSTOM_FUNCTION:
			if not target_node.has_method(custom_function):
				push_warning("Node doesn't have function named '%s'" % custom_function)
				return
			target_node.call(custom_function)
func _validate_property(property: Dictionary) -> void: # hide certain properties.
	const HIDE_PROPS: PackedStringArray = [
		"options",
		# this was extending OptionItem before lol
		#"name", "setting", "description", "min_value", "max_value", 
		#"num_step", "type", "default", "enum_values"
	]
	if property.name in HIDE_PROPS:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	# Show only relevant properties based on action type
	match action_type:
		Type.OPEN_SUBMENU:
			if property.name in ["scene_path", "custom_function"]: property.usage = PROPERTY_USAGE_NO_EDITOR
		Type.SCENE_CHANGE:
			if property.name in ["submenu_path", "custom_function"]: property.usage = PROPERTY_USAGE_NO_EDITOR
		Type.SCENE_REWIND:
			if property.name in ["scene_path", "submenu_path", "custom_function"]: property.usage = PROPERTY_USAGE_NO_EDITOR
		Type.CUSTOM_FUNCTION:
			if property.name in ["submenu_path", "scene_path"]: property.usage = PROPERTY_USAGE_NO_EDITOR
