extends Control

signal started()
signal finished()

@onready var anim: AnimationPlayer = $"animation_player"
var duration: float = 1.0

func _ready() -> void:
	duration = anim.get_animation("transition").length
	anim.seek(0.0)

func play() -> void:
	anim.seek(0.0)
	anim.play("transition")
	started.emit()
	await anim.animation_finished
	finished.emit()
