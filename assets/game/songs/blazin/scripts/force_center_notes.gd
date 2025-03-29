extends Node
func _ready_post() -> void:
	var game: Gameplay = get_tree().current_scene
	var vps: Vector2 = game.get_viewport_rect().size
	game.note_fields.get_child(0).position.x = vps.x * 0.38
	game.note_fields.get_child(1).hide()
