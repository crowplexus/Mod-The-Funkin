extends Control

const LISTS: Dictionary[String, PackedStringArray] = {
	"default": ["Resume", "Restart", "Difficulty", "Options", "Exit"],
}

@onready var blue_panel: Panel = $"panel"
@onready var level_label: Label = $"panel/song_name"
@onready var diffc_label: Label = $"panel/song_name/difficulty_name"

@onready var bg: ColorRect = $"background"
@onready var template: Label = $"panel/options/template".duplicate()
@onready var menu_options: Control = $"panel/options"
@onready var progress_bar: ProgressBar = $"panel/progress_bar"
@onready var progress_label: Label = $"panel/progress_bar/label"
@onready var options_menu: CanvasLayer = $"options_menu"

var list: PackedStringArray = []
var difficulties: PackedStringArray = []
var can_control: bool = false
var selected: int = 0
var tween: Tween

func _ready() -> void:
	Global.update_discord("Paused")
	
	progress_bar.value = Conductor.time / Conductor.length * progress_bar.max_value
	var t: String = Global.format_to_time(clampf(Conductor.time, 0.0, Conductor.length))
	var l: String = Global.format_to_time(Conductor.length)
	progress_label.text = t + " " + l
	
	if Gameplay.current:
		if "difficulties" in Gameplay.chart.parsed_values and Gameplay.game_mode == Gameplay.GameMode.FREEPLAY:
			difficulties = Gameplay.chart.parsed_values.difficulties.duplicate()
		
		level_label.text = Gameplay.current.song_name
		if not Gameplay.chart.artist.is_empty():
			level_label.text += " — %s" % Gameplay.chart.artist
		var difficulty: String = Gameplay.current.difficulty_name
		var tr_diff: String = tr("difficulty_%s" % difficulty.to_lower(), &"menus")
		diffc_label.text = tr_diff if not tr_diff.begins_with("difficulty_") else difficulty
		if not Gameplay.chart.charter.is_empty():
			diffc_label.text += " — Chart: %s" % Gameplay.chart.charter
		
	if difficulties.size() > 1 and not difficulties.has("BACK"):
		difficulties.append("BACK")
	load_default_list()
	
	blue_panel.position.x = -get_viewport_rect().size.x
	tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE).set_parallel(true)
	tween.tween_property(blue_panel, "position:x", 0.0, 0.4)
	
	var og_mod_a: float = bg.modulate.a
	bg.modulate.a = 0.0
	tween.tween_property(bg, "modulate:a", og_mod_a, 0.4)
	
	reload_options()
	$"panel/options/template".queue_free()
	template.hide()

	await get_tree().create_timer(0.1).timeout
	can_control = true

func load_default_list() -> void:
	var options: Array = LISTS.default.duplicate()
	if difficulties.size() <= 1:
		options.remove_at(2)
	list = options

func _unhandled_input(event: InputEvent) -> void:
	if not can_control or event.is_echo(): return
	var accepting: bool = event.is_action("ui_accept") and event.pressed
	# keyboard controls #
	var axis: int = floori(Input.get_axis("ui_up", "ui_down"))
	if axis != 0: change_selection(axis)
	if accepting:
		if is_same(list, difficulties):
			var selected_diff: String = difficulties[selected].dedent().to_snake_case()
			if selected_diff == "back":
				load_default_list()
				reload_options()
			else:
				Gameplay.set_playlist([Gameplay.current.chart.parsed_values.song_name], selected_diff)
				Gameplay.chart.parsed_values.difficulties = difficulties
				Global.reload_scene()
				close()
		else:
			confirm_selection()

func confirm_selection() -> void:
	var game: = get_tree().current_scene
	match list[selected].dedent().to_lower():
		"resume":
			if game is Gameplay and not game.starting and not game.ending:
				game.music.play(Conductor.time)
			get_tree().paused = false
			close()
		"restart":
			if game is Gameplay: game.restart_song()
			get_tree().paused = false
			close()
		"difficulty":
			list = difficulties
			reload_options()
		"options":
			can_control = false
			var fuck: Control = load("uid://gulb1ge3va36").instantiate()
			add_child(fuck)
			await fuck.tree_exited
			if Gameplay.current:
				if Gameplay.current.hud:
					Gameplay.current.hud.settings_changed(Gameplay.current.local_settings)
				if Gameplay.current.note_group:
					for note: Note in Gameplay.current.note_group.get_children():
						note.reset_scroll()
					Gameplay.current.note_group.move_present_nodes()
				# swap the huds if we can.
				if Gameplay.current.hud_is_built_in == true and Gameplay.current.local_settings.hud_style != Global.settings.hud_style:
					Gameplay.current.local_settings.hud_style = Global.settings.hud_style
					Gameplay.current.reload_hud()
			can_control = true
		"exit":
			can_control = false
			Gameplay.exit_to_menu()

## Changes the index of the selection cursor
func change_selection(next: int = 0) -> void:
	var item: Control = menu_options.get_child(selected)
	selected = wrapi(selected + next, 0, menu_options.get_child_count())
	Global.play_sfx(Global.resources.get_resource("scroll"))
	if item: item.modulate.a = 0.6
	item = menu_options.get_child(selected)
	item.modulate.a = 1.0

## Reloads all of the options.
func reload_options() -> void:
	for i: Control in menu_options.get_children(): i.queue_free()
	selected = 0 # TODO: find old selection and return to it.
	for i: int in list.size():
		var entry: Label = template.duplicate()
		var context: String = "difficulty_" if is_same(list, difficulties) else "pause_"
		entry.text = tr(context + "%s" % list[i].to_lower(), &"menus")
		entry.modulate.a = 1.0 if selected == i else 0.6
		entry.show() # just to be sure.
		menu_options.add_child(entry)
	change_selection()

## Closes the pause menu.
func close() -> void:
	can_control = false
	self.queue_free()
