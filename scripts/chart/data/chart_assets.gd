## Assets used for the charts, inspired by what-is-a-git/FunkinGodot
class_name ChartAssets extends Resource

@export var instrumental: AudioStream ## The chart's song instrumental
@export var vocals: Array[AudioStream] = [] ## The chart's song vocals (if any)
@export var note_skin: NoteSkin = preload("uid://dxhq200ow8ypp") ## The noteskin used in the song.
@export var hud: PackedScene ## The HUD scene that will be used for the song, if unspecified, the game will use the default one.
@export var pause_menu: PackedScene ## The Pause Menu scene that will be used for the song, if unspecified, the game will use the default one.

## The Countdown Sprite Frames that will be used for the early-song countdown.
@export var countdown_assets: Array[Texture2D] = [
	preload("uid://eoyumqwmgfpq"),
	preload("uid://our5ag8vgeit"),
	preload("uid://c171hewdxpuy4"),
	preload("uid://c5ncodoxcgphl"),
]
## Textures to display for each judgement.
@export var judgement_assets: Dictionary[String, Texture2D] = {
	"epic": preload("uid://bjyr01qah5nj3"),
	"sick": preload("uid://bbso4bx4gyag5"),
	"good": preload("uid://ln8kwo702lx6"),
	"bad" : preload("uid://oc4gpybrbw7r"),
	"shit": preload("uid://bdvlysb4ywney"),
}
## Texture to be used for the combo numbers, must be a full spritesheet with 10 frames.
@export var combo_numbers: Texture2D = preload("uid://cyni3widg3lqh")

@export var countdown_scale: Vector2 = Vector2(0.7, 0.7) ## Scale for the countdown popup.
@export var judgement_scale: Vector2 = Vector2(0.65, 0.65) ## Scale for the judgement sprite popup.
@export var combo_scale: Vector2 = Vector2(0.45, 0.45) ## Scale for the combo number popup.

## The Countdown Sounds that will be used for the early-song countdown.
@export var countdown_sounds: Array[AudioStream] = [
	preload("uid://cs4y7h8cnhhwm"),
	preload("uid://c4y5bwvxdkv4o"),
	preload("uid://c72s73suuam2n"),
	preload("uid://177yqxrxg1hf"),
]
## Miss Sounds that will be used when missing notes.
@export var miss_note_sounds: Array[AudioStream] = [
	preload("uid://1ahkreqvoty3"),
	preload("uid://c1pqgmd00h20b"),
	preload("uid://j4gb0khptavt"),
]

## Returns the song path (with variation included) if possible.
static func song_path(song_name: String, variation: String = "", add: String = "") -> String:
	var ret: String = "res://assets/game/songs/" + song_name
	# make sure variation gets appended to the path, if not, append default
	if not ResourceLoader.exists(ret + "/" + variation):
		variation = "default"
	ret += "/" + variation + "/"
	if not DirAccess.dir_exists_absolute(ret):
		ret = ret.replace("/" + variation, "")
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
