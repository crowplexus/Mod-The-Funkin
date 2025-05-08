class_name NoteSkin extends Resource

@export var strum_scene: PackedScene = preload("res://scenes/gameplay/playfield/strumline/skin/rgb_strum.tscn")
@export var note_scenes: Dictionary[String, PackedScene] = {
	"_": preload("uid://gib0vewis1qh")
}
