extends Control

const LISTS: Dictionary[String, PackedStringArray] = {
	"default": ["Resume", "Restart", "Difficulty", "Options", "Exit"],
}
var options: PackedStringArray = LISTS.default.duplicate()
@onready var bg: ColorRect = $"background"
@onready var template: Label = $"options/template"
@onready var menu_options: Control = $"options"

var tween: Tween
var selected: int = 0
var can_control: bool = false

func _ready() -> void:
	Global.update_discord("Solo (1 of 1)", "Paused")
	options.remove_at(2) # remove "Difficulty" temporarily.
	
	tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE).set_parallel(true)
	
	for i: int in options.size():
		var entry: Label = template.duplicate()
		entry.modulate.a = 0.0
		entry.text = tr("pause_%s" % options[i].to_lower())
		tween.tween_property(entry, "modulate:a", 1.0 if selected == i else 0.6, 0.3 * i)
		menu_options.add_child(entry)
	menu_options.remove_child(template)
	
	var og_mod_a: float = bg.modulate.a
	tween.tween_property(bg, "modulate:a", og_mod_a, 0.6).set_delay(0.1)
	bg.modulate.a = 0.0
	await get_tree().create_timer(0.6).timeout
	can_control = true

func _unhandled_input(_event: InputEvent) -> void:
	if not can_control: return
	var accepting: bool = Input.is_action_just_pressed("ui_accept")
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
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	if item: item.modulate.a = 0.6
	item = menu_options.get_child(selected)
	item.modulate.a = 1.0

## Closes the pause menu.
func close() -> void:
	can_control = false
	get_tree().paused = false
	self.queue_free()
