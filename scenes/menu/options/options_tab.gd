extends Control

const OPTION_TRANSLATE_CONTEXT: StringName = &"options"

@onready var option_title: Label = $"description/option"
@onready var option_infor: RichTextLabel = $"description/info"
@onready var tab_name: Label = $"tabs/tab_name"
@onready var tabs_control: Control = $"tabs"

var selected: int = 0
var selected_tab: int = 0
var visible_tab: StringName = &"gameplay"
var changing_option: bool = false
var tabs: PackedStringArray = []
var current_tab: Control
var settings: Settings

func _ready() -> void:
	settings = Global.settings
	get_tree().paused = false
	#if Gameplay.current and Gameplay.current.local_settings:
	#	settings = Gameplay.current.local_settings
	for tab: Control in tabs_control.get_children():
		if tab is BoxContainer and tab.get_child_count() != 0:
			tabs.append(tab.name)
	reload_labels()
	switch_tabs()

func _unhandled_input(_event: InputEvent) -> void:
	var tab_axis: int = int(Input.get_axis("ui_left", "ui_right"))
	var opt_axis: int = int(Input.get_axis("ui_up", "ui_down"))
	if tab_axis != 0:
		if not changing_option:
			switch_tabs(tab_axis)
		else:
			var selected_option: Control = current_tab.get_child(selected)
			if selected_option is OptionBar:
				selected_option.update_value(tab_axis)
	if opt_axis != 0 and not changing_option:
		change_selection(opt_axis)
	if Input.is_action_just_pressed("ui_accept"):
		changing_option = not changing_option
		update_hover()
		
	if Input.is_action_just_pressed("ui_cancel"):
		if changing_option:
			changing_option = false
			update_hover()
		else:
			change_altered_settings()
			Global.rewind_scene()

func change_selection(next: int = 0) -> void:
	if not current_tab:
		return
	var previous_selected: int = selected
	selected = wrapi(selected + next, 0, current_tab.get_child_count())
	if selected != previous_selected:
		Global.play_sfx(Global.resources.get_resource("scroll"))
		var previous_option: Control = current_tab.get_child(previous_selected)
		if previous_option is OptionBar:
			previous_option.is_hovered = false
			previous_option.modulate.v = 1
	var selected_option: Control = current_tab.get_child(selected)
	if selected_option is OptionBar:
		selected_option.is_hovered = true
		option_title.text = selected_option.display_name
		option_infor.text = selected_option.description
	selected_option.modulate.v = 0.8

func switch_tabs(next: int = 0) -> void:
	var previous_tab: int = selected_tab
	selected_tab = wrapi(selected_tab + next, 0, tabs.size())
	if selected_tab != previous_tab:
		Global.play_sfx(Global.resources.get_resource("scroll"))
		visible_tab = tabs[selected_tab]
	tab_name.text = "< %s >" % [ tr("options_tab_%s" % visible_tab, OPTION_TRANSLATE_CONTEXT) ]
	update_visible_tabs()

func update_visible_tabs() -> void:
	for tab: Control in tabs_control.get_children():
		if tab is BoxContainer and tab.get_child_count() != 0:
			tab.visible = false
			if tab.name == visible_tab:
				tab.visible = true
				current_tab = tab
	change_selection()

func change_altered_settings() -> void:
	for tab: Control in tabs_control.get_children():
		if tab is BoxContainer and tab.get_child_count() != 0:
			for i: Control in tab.get_children():
				if i is OptionBar and settings:
					i.update_setting()
	settings.update_all()

func save_to_disk() -> void:
	pass

func update_hover() -> void:
	var option: Control = current_tab.get_child(selected)
	if option is OptionBar:
		# PLACEHOLDER ↓ ↓ ↓
		option.get_child(0).modulate = Color.CYAN if changing_option else Color.WHITE
		option.get_child(1).get_child(0).modulate = Color.CYAN if changing_option else Color.WHITE

func reload_labels() -> void:
	tab_name.text = tr("options_tab_%s" % visible_tab, OPTION_TRANSLATE_CONTEXT)
	for tab: Control in tabs_control.get_children():
		if tab is BoxContainer and tab.get_child_count() != 0:
			tabs.append(tab.name)
			for i: Control in tab.get_children():
				if i is OptionBar: # translate labels.
					i.name_label.text = tr("option_%s" % i.variable_name)
