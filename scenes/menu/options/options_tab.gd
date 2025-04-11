extends Control

@onready var option_title: Label = $"description/option"
@onready var option_infor: RichTextLabel = $"description/info"

var selected: int = 0
var selected_tab: int = 0
var visible_tab: StringName = &"gameplay"
var tabs: PackedStringArray = []
var current_tab: Control

func _ready() -> void:
	for i: Control in get_children():
		if (i is VBoxContainer or i is HBoxContainer) and i.get_child_count() != 0:
			tabs.append(i.name)
	switch_tabs()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	#var opt_axis: int = int(Input.get_axis("ui_up", "ui_down"))
	#if opt_axis != 0: change_option(opt_axis)
	var tab_axis: int = int(Input.get_axis("ui_left", "ui_right"))
	var opt_axis: int = int(Input.get_axis("ui_up", "ui_down"))
	if tab_axis != 0: switch_tabs(tab_axis)
	if opt_axis != 0: change_selection(opt_axis)

func change_selection(next: int = 0) -> void:
	if not current_tab:
		return
	var previous_selected: int = selected
	selected = wrapi(selected + next, 0, current_tab.get_child_count())
	if selected != previous_selected:
		Global.play_sfx(Global.resources.get_resource("scroll"))
	var selected_option: Control = current_tab.get_child(selected)
	if selected_option and selected_option.display_name:
		option_title.text = selected_option.display_name
		option_infor.text = selected_option.description

func switch_tabs(next: int = 0) -> void:
	var previous_tab: int = selected_tab
	selected_tab = wrapi(selected_tab + next, 0, tabs.size())
	if selected_tab != previous_tab:
		Global.play_sfx(Global.resources.get_resource("scroll"))
		visible_tab = tabs[selected_tab]
	update_visible_tabs()

func update_visible_tabs() -> void:
	for i: Control in get_children():
		if i is BoxContainer and i.get_child_count() != 0:
			i.visible = false
			if i.name == visible_tab:
				current_tab = i
				i.visible = true
				change_selection()
