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
## Miss Sounds that will be used when missing notes.
@export var miss_note_sounds: Array[AudioStream] = [
	preload("res://assets/sounds/miss/funkin/miss1.ogg"),
	preload("res://assets/sounds/miss/funkin/miss2.ogg"),
	preload("res://assets/sounds/miss/funkin/miss3.ogg"),
]

## Returns an assets resource from the specified path (if it exists)[br]
## Will return a a default resource on fail.
static func get_resource(song_name: String, difficulty: String, fallback: ChartAssets = Global.DEFAULT_CHART_ASSETS) -> ChartAssets:
	var path: String = "res://assets/game/songs/%s/default/assets.tres" % [song_name]
	var variation_path: String = path.replace("/default/", "/%s/" % solve_variation(difficulty))
	if ResourceLoader.exists(variation_path):
		path = variation_path
	if not ResourceLoader.exists(path):
		var file: String = path.get_file()
		path = Chart.fix_path(path.replace(file, "")) + ".tres"
		if not ResourceLoader.exists(path):
			return fallback
	return load(path)

static func solve_variation(difficulty: String) -> String:
	var x: String = difficulty.to_lower().strip_edges().strip_escapes()
	return Global.DEFAULT_VARIATION_BINDINGS[x] if difficulty in Global.DEFAULT_VARIATION_BINDINGS else x
