extends Control

# TODO: rewrite this.

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
var current_tab: Array[Control] = []
var settings: Settings

func _ready() -> void:
	if not settings:
		#if Gameplay.current:
		#	settings = Gameplay.current.local_settings
		#else:
		settings = Global.settings
	for tab: Control in tabs_control.get_children():
		if tab is BoxContainer and tab.get_child_count() != 0:
			tabs.append(tab.name)
	reload_labels()
	switch_tabs()

func _unhandled_input(event: InputEvent) -> void:
	var tab_axis: int = int(Input.get_axis("ui_left", "ui_right"))
	var opt_axis: int = int(Input.get_axis("ui_up", "ui_down"))
	var selected_option: Control = current_tab[selected]
	if tab_axis != 0:
		if not changing_option:
			switch_tabs(tab_axis)
		else:
			if selected_option is OptionBar:
				selected_option.update_value(tab_axis)
				changing_option = selected_option.changing # in case options change it.
				selected_option.update_hover()
	
	if opt_axis != 0 and not changing_option:
		change_selection(opt_axis)
	
	if Input.is_action_just_pressed("ui_accept"):
		changing_option = not changing_option
		selected_option.changing = changing_option
		selected_option.update_hover()
	
	if Input.is_action_just_pressed("ui_cancel"):
		if changing_option:
			changing_option = false
			selected_option.changing = false
			selected_option.update_hover()
		else:
			change_altered_settings()
			if Gameplay.current:
				queue_free()
			else:
				Global.rewind_scene()

func change_selection(next: int = 0) -> void:
	if current_tab.is_empty():
		return
	var previous_selected: int = selected
	selected = wrapi(selected + next, 0, current_tab.size())
	if selected != previous_selected:
		Global.play_sfx(Global.resources.get_resource("scroll"))
	for i: int in current_tab.size():
		var option: Control = current_tab[i]
		option.modulate.v = 0.8 if selected == i else 1.0
	var selected_option: Control = current_tab[selected]
	option_title.text = tr("option_%s" % selected_option.name)
	if selected_option is OptionBar: option_infor.text = selected_option.description

func switch_tabs(next: int = 0) -> void:
	var previous_tab: int = selected_tab
	selected_tab = wrapi(selected_tab + next, 0, tabs.size())
	if selected_tab != previous_tab:
		Global.play_sfx(Global.resources.get_resource("scroll"))
		visible_tab = tabs[selected_tab]
	tab_name.text = "< %s >" % [ tr("options_tab_%s" % visible_tab, OPTION_TRANSLATE_CONTEXT) ]
	update_visible_tabs()

func update_visible_tabs() -> void:
	current_tab.clear()
	for tab: Control in tabs_control.get_children():
		if tab is BoxContainer and tab.get_child_count() != 0:
			tab.visible = false
			if tab.name == visible_tab:
				tab.visible = true
				for i: Control in tab.get_children():
					if i.visible and i is OptionBar:
						i.changing = false
						current_tab.append(i)
	if selected > current_tab.size(): selected = 0
	change_selection()

func change_altered_settings() -> void:
	for tab: Control in tabs_control.get_children():
		if tab is BoxContainer and tab.get_child_count() != 0:
			for i: Control in tab.get_children():
				if i.visible and i is OptionBar:
					i.update_setting()
	settings.update_all()

func reload_labels() -> void:
	tab_name.text = tr("options_tab_%s" % visible_tab, OPTION_TRANSLATE_CONTEXT)
	for tab: Control in tabs_control.get_children():
		if tab is BoxContainer and tab.get_child_count() != 0:
			tabs.append(tab.name)
			for i: Control in tab.get_children():
				if i is OptionBar: # translate labels.
					i.name_label.text = tr("option_%s" % i.name)
