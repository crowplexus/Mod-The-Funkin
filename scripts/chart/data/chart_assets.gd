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

static func solve_song_path(song_name: String, variation: String = Global.DEFAULT_DIFFICULTY) -> String:
	var path: String = "res://assets/game/songs/%s/%s/" % [ song_name, variation ]
	if not DirAccess.dir_exists_absolute(path): path = path.replace("/%s/" % variation, "/default/")
	return path

## Returns an assets resource from the specified path (if it exists)[br]
## Will return a a default resource on fail.
static func get_resource(song_name: String, difficulty: String, fallback: ChartAssets = Global.DEFAULT_CHART_ASSETS) -> ChartAssets:
	var variation: String = ChartAssets.solve_variation(difficulty)
	var path: String = ChartAssets.solve_song_path(song_name, variation) + "assets.tres"
	if not ResourceLoader.exists(path):
		var file: String = path.get_file()
		if not ResourceLoader.exists(Chart.fix_path(path.replace(file, "")) + file):
			print_debug("song ", song_name, " has no metadata file, using defaults")
			var fb: ChartAssets = fallback.duplicate()
			var audio_path: String = ChartAssets.solve_song_path(song_name, variation)
			if not fb.instrumental and ResourceLoader.exists(audio_path + "Inst.ogg"):
				fb.instrumental = AudioStreamOggVorbis.load_from_file(audio_path + "Inst.ogg")
				print_debug("found instrumental for ", song_name)
			var vocal_index: int = 0
			for i: String in ["Voices-Player.ogg", "Voices-Opponent.ogg", "Voices.ogg"]:
				if vocal_index > 2 and fb.vocals.size() != 0: break # break if there's Player/Enemy separate vocals.
				if ResourceLoader.exists(audio_path + i):
					fb.vocals.append(AudioStreamOggVorbis.load_from_file(audio_path + i))
					print_debug("found vocal track ", i ," for ", song_name)
				vocal_index += 1
			return fb
	return load(path)

static func solve_variation(difficulty: String) -> String:
	var x: String = difficulty.to_lower().strip_edges().strip_escapes()
	return Global.DEFAULT_VARIATION_BINDINGS[x] if difficulty in Global.DEFAULT_VARIATION_BINDINGS else x
