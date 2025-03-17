## Assets used for the charts, inspired by what-is-a-git/FunkinGodot
class_name ChartAssets
extends Resource

## The chart's song instrumental
@export var instrumental: AudioStream
## The chart's song vocals (if any)
@export var vocals: Array[AudioStream] = []
## The noteskin used in the song.
@export var note_skin: NoteSkin = preload("res://assets/default/noteskin.tres")
## The HUD scene that will be used for the song, if unspecified, the game will use the default one.
@export var hud: PackedScene
## The Pause Menu scene that will be used for the song, if unspecified, the game will use the default one.
@export var pause_menu: PackedScene
## The Countdown Textures that will be used for the early-song countdown.
@export var countdown_textures: Array[Texture2D] = [
	preload("res://assets/ui/countdown/prepare.png"),
	preload("res://assets/ui/countdown/ready.png"),
	preload("res://assets/ui/countdown/set.png"),
	preload("res://assets/ui/countdown/go.png"),
]
## The Countdown Sounds that will be used for the early-song countdown.
@export var countdown_sounds: Array[AudioStream] = [
	preload("res://assets/sounds/countdown/funkin/3.ogg"),
	preload("res://assets/sounds/countdown/funkin/2.ogg"),
	preload("res://assets/sounds/countdown/funkin/1.ogg"),
	preload("res://assets/sounds/countdown/funkin/go.ogg"),
]
