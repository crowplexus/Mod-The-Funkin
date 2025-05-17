extends Node2D

enum MenuState { MAIN, CATEGORY, OCCUPIED }

func _open_note_colours() -> void:
	menu_items.hide()
	await open_submenu("uid://b3n6ic3en6yow")
	menu_items.show()

func _exit_menu() -> void:
	if Gameplay.current:
		create_tween().set_ease(Tween.EASE_OUT).tween_property(self, "modulate:a", 0.0, 0.3) \
			.finished.connect(queue_free)
	else:
		Global.rewind_scene()

var categories: Dictionary[String, CategoryOptions] = {
	# if you wanna modify these probably go to res://assets/resources/options
	"gameplay": preload("uid://n22ut3j84o16"),
	"controls": CategoryAction.new(CategoryAction.Type.OPEN_SUBMENU, "", "uid://dqxmfmm8a11j6"),
	"visuals": preload("uid://bxaiw0f16bjes"),
	"notes": CategoryAction.new(CategoryAction.Type.CUSTOM_FUNCTION, "_open_note_colours"),
	"exit": CategoryAction.new(CategoryAction.Type.CUSTOM_FUNCTION, "_exit_menu"),
}
@onready var background: Sprite2D = $"background"
@onready var menu_items: AlphabetMenu = $"menu_items"
@onready var description_label: Label = $"description"
@onready var category_names: Array[String] = categories.keys()
@onready var menu_offset_y: float = menu_items.offset.y

var can_input: bool = false
var current_state := MenuState.MAIN
var current_category: String = "main"
var current_option: OptionItem:
	get:
		var options: Array = categories[current_category].options
		return options[selected] if selected < options.size() else null
var selected: int = 0

func open_submenu(uid: String) -> bool:
	set_process_unhandled_input(false)
	var controls_menu: Control = load(uid).instantiate()
	controls_menu.size = get_viewport_rect().size # it can be small apparently.
	controls_menu.z_index = 666 # is that enough? ok.
	add_child(controls_menu)
	await controls_menu.tree_exited
	set_process_unhandled_input(true)
	return true

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
	background.modulate.h += 1.0 + sin(PI * (5 * delta)/360)

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
				var schwa: CategoryOptions = categories[current_category]
				if schwa is CategoryAction:
					schwa.execute_func(self)
				else:
					reload_options()
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
				_exit_menu()
		
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
			if change_axis != 0:
				current_option.change(change_axis)
				Global.play_sfx(Global.resources.get_resource("scroll"))
				menu_items.get_child(selected).text = get_option_display(current_option, current_option.current_value)
			if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
				current_state = MenuState.CATEGORY
				update_item_visual()

func reload_options(main: bool = false) -> void:
	if not main:
		current_state = MenuState.CATEGORY
		current_category = category_names[selected]
		menu_items.items = get_settings_in_category()
		if not categories[current_category].options.is_empty(): # prevent crash from empty category
			description_label.text = categories[current_category].options[0].description
		menu_items.offset.y = menu_offset_y
	else:
		current_category = "main"
		current_state = MenuState.MAIN
		menu_items.items = category_names
		menu_items.offset.y = 0
	selected = 0
	var is_cat: bool = current_category in categories and not categories[current_category].options.is_empty() 
	description_label.visible = is_cat and current_state == MenuState.CATEGORY
	menu_items.active = not main
	menu_items.regen_list()
	update_item_visual()

func change_selection(next: int = 0) -> void:
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	selected = wrapi(selected + next, 0, menu_items.items.size())
	if description_label.visible and current_option:
		description_label.text = current_option.description
	update_item_visual()

func update_item_visual() -> void:
	menu_items.focus_item(selected)
	for idx: int in menu_items.get_child_count():
		var item: Control = menu_items.get_child(idx)
		if not menu_items.active: item.modulate.a = 1.0 if idx == selected else 0.6
		if idx == selected and current_state == MenuState.OCCUPIED:
			item.modulate = Color.CYAN

func get_settings_in_category() -> Array[String]:
	var sets: Array[String] = []
	for i: OptionItem in categories[current_category].options:
		if not categories[current_category] is CategoryOptions: continue
		if not i is OptionItem: continue
		sets.append(get_option_display(i, i.current_value))
	return sets

func get_option_display(option: OptionItem, value: Variant) -> String:
	var display_value: Variant = value
	match option.type:
		OptionItem.Type.BOOL: display_value = "on" if value else "off"
		OptionItem.Type.FLOAT: display_value = "%.2f" % value
		OptionItem.Type.ENUM:
			if value is int and value >= 0 and value < option.values.size():
				display_value = str(option.values[value])
			else:
				display_value = str(value)
		_:
			display_value = str(display_value)
	return "%s: %s" % [option.name, display_value]
