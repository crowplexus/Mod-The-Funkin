extends Control

signal on_close()

const LISTS: Dictionary[String, PackedStringArray] = {
	"default": ["Resume", "Restart", "Difficulty", "Options", "Exit"],
}

@onready var blue_panel: Panel = $"panel"
@onready var level_label: Label = $"panel/song_name"
@onready var diffc_label: Label = $"panel/difficulty_name"

@onready var bg: ColorRect = $"background"
@onready var template: Label = $"panel/options/template"
@onready var menu_options: Control = $"panel/options"

var options: PackedStringArray = LISTS.default.duplicate()
var can_control: bool = false
var selected: int = 0
var tween: Tween

func _ready() -> void:
	Global.update_discord("Paused")
	if Gameplay.current:
		level_label.text = Gameplay.current.song_name
		diffc_label.text = Gameplay.current.difficulty_name
	options.remove_at(2) # remove "Difficulty" temporarily.
	
	blue_panel.position.x = -get_viewport_rect().size.x
	print(blue_panel.position.x)
	tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE).set_parallel(true)
	tween.tween_property(blue_panel, "position:x", 0.0, 0.4)
	
	for i: int in options.size():
		var entry: Label = template.duplicate()
		entry.text = tr("pause_%s" % options[i].to_lower(), &"menus")
		entry.modulate.a = 1.0 if selected == i else 0.6
		menu_options.add_child(entry)
	menu_options.remove_child(template)
	
	var og_mod_a: float = bg.modulate.a
	tween.tween_property(bg, "modulate:a", og_mod_a, 0.4)
	bg.modulate.a = 0.0
	change_selection()
	await get_tree().create_timer(0.1).timeout
	can_control = true

func _unhandled_input(event: InputEvent) -> void:
	if not can_control or event.is_echo(): return
	var accepting: bool = event.is_action("ui_accept") and event.pressed
	# keyboard controls #
	var axis: int = floori(Input.get_axis("ui_up", "ui_down"))
	if axis != 0: change_selection(axis)
	if accepting:
		var game: = get_tree().current_scene
		match options[selected].dedent():
			"Resume":
				if game is Gameplay and not game.starting and not game.ending:
					game.music.play(Conductor.time)
				close()
			"Restart":
				if game is Gameplay: game.restart_song()
				close()
			"Exit":
				Global.change_scene("res://scenes/menu/freeplay_menu.tscn")

## Changes the index of the selection cursor
func change_selection(next: int = 0) -> void:
	var item: Control = menu_options.get_child(selected)
	selected = wrapi(selected + next, 0, menu_options.get_child_count())
	Global.play_sfx(Global.resources.get_resource("scroll"))
	if item: item.modulate.a = 0.6
	item = menu_options.get_child(selected)
	item.modulate.a = 1.0

## Closes the pause menu.
func close() -> void:
	can_control = false
	get_tree().paused = false
	on_close.emit()
	self.queue_free()
