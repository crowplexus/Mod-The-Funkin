extends Control

@onready var bg: ColorRect = $"background"

func _ready() -> void:
	Global.update_discord("had a built in emote", "what if Raven Team Leader")
	Global.update_discord_timestamps(0)

func _unhandled_key_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		var go: Callable = func() -> void: Global.change_scene("res://scenes/menu/freeplay_menu.tscn")
		create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING) \
		.tween_property(bg, "color", Color.BLACK, 0.5).finished.connect(go)
