extends Node2D
var menu_song: AudioStream = preload("res://assets/music/freakyMenu.ogg")
func _ready() -> void:
	Global.play_bgm(menu_song, 0.7)
	pass
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass
func _unhandled_key_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		Global.change_scene("res://scenes/menu/freeplay_menu.tscn")
	if Input.is_action_just_pressed("ui_cancel"):
		Global.bgm.stop()
		Global.change_scene(load("res://scenes/gameplay/adjacent/game_over.tscn"))
