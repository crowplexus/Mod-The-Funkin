## Assets used for the charts, inspired by what-is-a-git/FunkinGodot
class_name ChartAssets extends Resource

@export var instrumental: AudioStream ## The chart's song instrumental
@export var vocals: Array[AudioStream] = [] ## The chart's song vocals (if any)
@export var note_skin: NoteSkin = preload("res://assets/resources/noteskin.tres") ## The noteskin used in the song.
@export var hud: PackedScene ## The HUD scene that will be used for the song, if unspecified, the game will use the default one.
@export var pause_menu: PackedScene ## The Pause Menu scene that will be used for the song, if unspecified, the game will use the default one.

## The Countdown Sprite Frames that will be used for the early-song countdown.
@export var countdown_assets: Array[Texture2D] = [
	preload("res://assets/ui/popups/funkin/prepare.png"),
	preload("res://assets/ui/popups/funkin/ready.png"),
	preload("res://assets/ui/popups/funkin/set.png"),
	preload("res://assets/ui/popups/funkin/go.png"),
]
## Textures to display for each judgement.
@export var judgement_assets: Dictionary[String, Texture2D] = {
	"epic": preload("res://assets/ui/popups/funkin/epic.png"),
	"sick": preload("res://assets/ui/popups/funkin/sick.png"),
	"good": preload("res://assets/ui/popups/funkin/good.png"),
	"bad" : preload("res://assets/ui/popups/funkin/bad.png"),
	"shit": preload("res://assets/ui/popups/funkin/shit.png"),
}
## Texture to be used for the combo numbers, must be a full spritesheet with 10 frames.
@export var combo_numbers: Texture2D = preload("res://assets/ui/popups/funkin/score_numbers.png")

@export var countdown_scale: Vector2 = Vector2(0.7, 0.7) ## Scale for the countdown popup.
@export var judgement_scale: Vector2 = Vector2(0.65, 0.65) ## Scale for the judgement sprite popup.
@export var combo_scale: Vector2 = Vector2(0.45, 0.45) ## Scale for the combo number popup.

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

## Returns the song path (with variation included) if possible.
static func song_path(song_name: String, variation: String = "", add: String = "") -> String:
	var ret: String = "res://assets/game/songs/%s" % song_name
	if not variation.is_empty():
		var variation_ret: String = ret + "/%s" % variation
		var is_variation: bool = ResourceLoader.exists(variation_ret)
		ret += variation_ret if is_variation else "/default"
	if not add.is_empty(): ret += add
	return ret

## Returns an assets resource from the specified path (if it exists)[br]
## Will return a a default resource on fail.
static func get_resource(chart: Chart, fallback: ChartAssets = Global.DEFAULT_CHART_ASSETS) -> ChartAssets:
	var variation: String = chart.parsed_values.variation
	var song_name: String = chart.parsed_values.song_name
	var path: String = ChartAssets.song_path(song_name, variation, "/assets.tres")
	
	if not ResourceLoader.exists(path):
		var file: String = path.get_file()
		if not ResourceLoader.exists(Chart.fix_path(path.replace(file, "")) + file):
			var fb: ChartAssets = fallback.duplicate() # create fallback assets
			# find instrumental for the fallbacks
			var audio_path: String = ChartAssets.song_path(song_name, variation)
			if not fb.instrumental and ResourceLoader.exists(audio_path + "/Inst.ogg"):
				fb.instrumental = load(audio_path + "/Inst.ogg")
			
			if chart is FNFChart or chart is VSliceChart:
				var vocal_index: int = 0
				for i: String in ["/Voices-Player.ogg", "/Voices-Opponent.ogg", "/Voices.ogg"]:
					if not i.contains("-") and fb.vocals.size() != 0: break # break if there's Player/Enemy separate vocals.
					var push_vocal: bool = ResourceLoader.exists(audio_path + i)
					if not push_vocal and vocal_index < 2:
						var char_idx: int = vocal_index if vocal_index < 2 else -1
						if char_idx != -1 and "characters" in chart.parsed_values:
							i = i.replace("-Player", "-%s" % chart.parsed_values.characters[0]) \
								.replace("-Opponent", "-%s" % chart.parsed_values.characters[1]) \
								.replace("-DJ", "-%s" % chart.parsed_values.characters[2])
							push_vocal = ResourceLoader.exists(audio_path + i)
					# add vocal files (if possible)
					if push_vocal: fb.vocals.append(load(audio_path + i))
					vocal_index += 1
			return fb
	return load(path)

## Returns a variation from the specified difficulty (or just the difficulty there's no variation overrides).
static func solve_variation(difficulty: String) -> String:
	var x: String = difficulty.to_lower().strip_edges().strip_escapes()
	return Global.DEFAULT_VARIATION_BINDINGS[x] if difficulty in Global.DEFAULT_VARIATION_BINDINGS else x
