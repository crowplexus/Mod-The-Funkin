extends Control

var current_tab: int = 0
var visible_tab: StringName = &"gameplay"
var tabs: PackedStringArray = []

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
	if tab_axis != 0: switch_tabs(tab_axis)

func switch_tabs(next: int = 0) -> void:
	var previous_tab: int = current_tab
	current_tab = wrapi(current_tab + next, 0, tabs.size())
	if current_tab != previous_tab:
		Global.play_sfx(Global.resources.get_resource("scroll"))
		update_visible_tabs()

func update_visible_tabs() -> void:
	for i: Control in get_children():
		if (i is VBoxContainer or i is HBoxContainer) and i.get_child_count() != 0:
			i.visible = i.name == visible_tab
