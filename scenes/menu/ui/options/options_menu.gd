extends Node2D

enum MenuState { MAIN, CATEGORY, OCCUPIED }
enum OptionType { BOOL, INT, FLOAT, STRING, ENUM }

class OptionItem:
	var name: String
	var setting: String
	var type: OptionType # "just use typeof()" shut up I just want this to WORK.
	var current_value: Variant: # just in case.
		get: return Global.settings.get(setting)
		set(new_value): Global.settings.set(setting, new_value)
	var values: Variant
	
	func _init(p_name: String, p_setting: String, p_values: Variant = null) -> void:
		self.setting = p_setting
		self.name = p_name
		_set_type(p_values)
	
	func _set_type(p_values) -> void:
		if p_values == null: type = OptionType.BOOL
		elif p_values is Array or p_values is Dictionary:
			if p_values is Dictionary and p_values.has("step"):
				if p_values.step is int: type = OptionType.INT
				else: type = OptionType.FLOAT
			else:
				type = OptionType.ENUM
			self.values = p_values

var categories: Dictionary[String, Variant] = {
	"gameplay": [
		OptionItem.new("Scroll Direction", "scroll", ["Up", "Down"]),
		OptionItem.new( "Ghost Tapping", "ghost_tapping", ["Disabled", "When in silence", "Enabled"]),
		OptionItem.new( "Note Speed", "note_speed", {"min": 0.5, "max": 5.0, "step": 0.01}),
		OptionItem.new( "Note Speed Mode", "note_speed_mode", ["Default", "Multiply Chart's", "User-Constant", "BPM-Based"]),
		OptionItem.new( "Show 'Epic' Judgement", "use_epics"),
	],
	"controls": open_controls,
	"visuals": [
		OptionItem.new("Framerate", "framerate", {"min": 30, "max": 360, "step": 1}),
		OptionItem.new("VSync Mode", "vsync_mode", ["Capped", "Unlimited", "Mailbox", "Adaptive"]),
		OptionItem.new("HUD Style", "hud_style", ["Default", "Classic", "Advanced", "Psych"]),
		OptionItem.new("Timer Style", "timer_style", ["Hidden", "Time Left", "Time Elapsed", "Song Name", "Elapsed/Total"]),
		OptionItem.new("Note Splash Opacity", "note_splash_alpha", {"min": 0, "max": 100, "step": 1}),
		OptionItem.new("Health Bar Opacity", "health_bar_alpha", {"min": 0, "max": 100, "step": 1}),
		OptionItem.new("Simplify Popups", "simplify_popups"),
		OptionItem.new("Combo Stacking", "combo_stacking"),
	],
	"exit": Global.rewind_scene,
}
@onready var background: Sprite2D = $"background"
@onready var category_names: Array[String] = categories.keys()
@onready var menu_items: AlphabetMenu = $"menu_items"
@onready var menu_offset_y: float = menu_items.offset.y

var can_input: bool = false
var current_state := MenuState.MAIN
var current_category: String = "main"
var selected: int = 0

func open_controls() -> void:
	set_process_unhandled_input(false)
	var controls_menu: Control = load("uid://dqxmfmm8a11j6").instantiate()
	controls_menu.size = get_viewport_rect().size # it can be small apparently.
	controls_menu.z_index = 666 # is that enough? ok.
	add_child(controls_menu)
	await controls_menu.tree_exited
	set_process_unhandled_input(true)

func _ready() -> void:
	# make sure the song is playing.
	if Global.DEFAULT_SONG and not Conductor.is_music_playing() and not Gameplay.current:
		Conductor.set_music_stream(Global.DEFAULT_SONG)
		Conductor.bpm = Global.DEFAULT_SONG.bpm
		Conductor.play_music(0.0, 0.7)
	
	if Gameplay.current: # if the menu was opened from the Gameplay scene, that is.
		background.modulate.a = 0.3 # since it's over the pause menu.
	
	menu_offset_y = menu_items.offset.y
	menu_items.list_regenerated.connect(update_item_visual)
	reload_options(true)
	can_input = true

func _process(delta: float) -> void:
	# welcome back to Windows 8 out of box experience.
	background.modulate.h += 1.0 + sin(PI * (10 * delta)/360)

func _unhandled_input(_event: InputEvent) -> void:
	if not can_input:
		return
	
	match current_state:
		MenuState.MAIN:
			var move_axis: int = int(Input.get_axis("ui_up", "ui_down"))
			if move_axis != 0: change_selection(move_axis)
			if Input.is_action_just_pressed("ui_accept"):
				can_input = false
				current_category = category_names[selected]
				Global.play_sfx(Global.resources.get_resource("confirm"))
				await Global.begin_flicker(menu_items.get_child(selected), 0.35, 0.04, true, false)
				var schwa: Variant = categories[current_category]
				match typeof(schwa):
					TYPE_CALLABLE: schwa.call()
					TYPE_ARRAY: reload_options()
				await get_tree().create_timer(0.1).timeout # calm down.
				can_input = true
			if Input.is_action_just_pressed("ui_cancel"):
				can_input = false
				selected = category_names.find("exit")
				if selected != -1: # option still exists and you didn't delete it for some reason.
					update_item_visual()
					Global.play_sfx(Global.resources.get_resource("confirm"))
					await Global.begin_flicker(menu_items.get_child(selected), 0.35, 0.04, true, false)
				else:
					Global.play_sfx(Global.resources.get_resource("cancel"))
				if Gameplay.current:
					create_tween().set_ease(Tween.EASE_OUT).tween_property(self, "modulate:a", 0.0, 0.3) \
						.finished.connect(queue_free)
				else:
					Global.rewind_scene()
		
		MenuState.CATEGORY:
			var move_axis: int = int(Input.get_axis("ui_up", "ui_down"))
			if move_axis != 0: change_selection(move_axis)
			if Input.is_action_just_pressed("ui_accept"):
				current_state = MenuState.OCCUPIED
			if Input.is_action_just_pressed("ui_cancel"):
				current_state = MenuState.MAIN
				reload_options(true)
			
		MenuState.OCCUPIED:
			var change_axis: int = int(Input.get_axis("ui_left", "ui_right"))
			if change_axis != 0: change_option_selected(change_axis)
			if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
				current_state = MenuState.CATEGORY
				update_item_visual()

func reload_options(main: bool = false) -> void:
	if not main:
		current_state = MenuState.CATEGORY
		current_category = category_names[selected]
		menu_items.items = get_settings_in_category()
		menu_items.offset.y = menu_offset_y
	else:
		current_category = "main"
		current_state = MenuState.MAIN
		menu_items.items = category_names
		menu_items.offset.y = 0
	
	selected = 0
	menu_items.active = not main
	menu_items.regen_list()
	update_item_visual()

func change_selection(next: int = 0) -> void:
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	selected = wrapi(selected + next, 0, menu_items.items.size())
	update_item_visual()

func update_item_visual() -> void:
	menu_items.focus_item(selected)
	for idx: int in menu_items.get_child_count():
		var item: Control = menu_items.get_child(idx)
		if not menu_items.active: item.modulate.a = 1.0 if idx == selected else 0.6
		if idx == selected and current_state == MenuState.OCCUPIED:
			item.modulate = Color.CYAN

func change_option_selected(change: int = 0) -> void:
	var option: OptionItem = categories[current_category][selected]
	var new_value: Variant = null
	match option.type:
		OptionType.BOOL when change != 0: new_value = not option.current_value
		OptionType.INT, OptionType.FLOAT:
			var step = option.values.get("step", 1.0) * (10.0 if Input.is_key_label_pressed(KEY_SHIFT) else 1.0)
			var minv = option.values.get("min", 0.0)
			var maxv = option.values.get("max", 1.0)
			new_value = wrap(option.current_value + (change * step), minv, maxv + 1.0)
		OptionType.ENUM:
			if option.current_value is int:
				new_value = wrapi(option.current_value + change, 0, option.values.size())
			else:
				var current_index = option.values.find(option.current_value)
				if current_index == -1:  # Fallback if value missing
					current_index = 0
				new_value = option.values[wrapi(current_index + change, 0, option.values.size())]
	
	menu_items.get_child(selected).text = get_option_display(option, new_value)
	option.current_value = new_value

func get_settings_in_category() -> Array[String]:
	var sets: Array[String] = []
	for i: Variant in categories[current_category]:
		if not i is OptionItem: continue
		sets.append(get_option_display(i, i.current_value))
	return sets

func get_option_display(option: OptionItem, value: Variant) -> String:
	var display_value: Variant = value
	match option.type:
		OptionType.BOOL: display_value = "on" if value else "off"
		OptionType.FLOAT: display_value = "%.2f" % value
		OptionType.ENUM:
			if value is int and value >= 0 and value < option.values.size():
				display_value = str(option.values[value])
			else:
				display_value = str(value)
		_:
			display_value = str(display_value)
	return "%s: %s" % [option.name, display_value]
