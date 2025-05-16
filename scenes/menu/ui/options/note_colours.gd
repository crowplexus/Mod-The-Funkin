extends Control

@onready var notes: HBoxContainer = $"strums"

func _ready() -> void:
	for i: StrumNote in notes.get_children():
		i.play_animation(StrumNote.States.PRESS, true)

func _unhandled_input(event: InputEvent) -> void:
	if event and not event.is_echo() and event.is_action("ui_cancel"):
		queue_free()
