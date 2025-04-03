extends Node

#region Node Tree
@onready var bgm: AudioStreamPlayer = $"%background_music"
@onready var sfx: Node = $"%sound_effects"
@onready var resources: ResourcePreloader = $"%resource_preloader"

var settings: Settings

func _ready() -> void:
	settings = Settings.new()
	settings.update_master_volume()
	settings.reload_locale()
	settings.reload_keybinds()
	settings.update_framerate()
	settings.update_vsync()
	reset_discord()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed:
		if not event.is_echo() and event.is_action("fullscreen"):
			var is_full: bool = get_window().mode == Window.Mode.MODE_FULLSCREEN
			get_window().mode = Window.MODE_WINDOWED if is_full else Window.MODE_FULLSCREEN
#endregion

#region Utils

func change_scene(next, immediate: bool = false) -> void:
	# TODO: transition
	if immediate: await get_tree().create_timer(0.5).timeout
	if next is String: get_tree().change_scene_to_file(next)
	elif next is PackedScene: get_tree().change_scene_to_packed(next)

#endregion

#region Music
var music_fade_tween: Tween

## [see]lerpf[/see]
func lerpv2(v1: Vector2, v2: Vector2, weight: float = 1.0) -> Vector2:
	return Vector2(
		lerpf(v1.x, v2.x, weight),
		lerpf(v1.y, v2.y, weight)
	)
##
func request_audio_fade(player: AudioStreamPlayer, to: float = 0.0, speed: float = 1.0) -> AudioStreamPlayer:
	if to < 0.0: return
	if music_fade_tween: music_fade_tween.stop()
	var new_vol: float = linear_to_db(to)
	var cur_vol: float = db_to_linear(player.volume_db)
	music_fade_tween = create_tween().set_ease(Tween.EASE_IN if new_vol > cur_vol else Tween.EASE_OUT)
	music_fade_tween.tween_property(player, "volume_db", new_vol, speed)
	return player

## Plays background music (remember to stop it if you're switching to a scene that has custom music nodes).
func play_bgm(stream: AudioStream, volume: float = 1.0, loop: bool = true) -> AudioStreamPlayer:
	bgm.stop()
	bgm.stream = stream
	bgm.volume_db = linear_to_db(volume)
	#bgm.pitch_scale = pitch
	bgm.stream.loop = loop
	bgm.play(0.0)
	return bgm

## Plays a sound effect.
func play_sfx(stream: AudioStream, volume: float = 0.7, pitch: float = 1.0) -> void:
	var asp: AudioStreamPlayer = AudioStreamPlayer.new()
	asp.bus = "Sound Effects"
	asp.stream = stream
	asp.pitch_scale = pitch
	asp.volume_db = linear_to_db(volume)
	asp.finished.connect(asp.queue_free)
	sfx.add_child(asp)
	asp.play(0.0)
#endregion

#region Math
# its not like I'm changing any of these
## Minimum value for logarithmic operations.
const LOG_MINIMUM: float = log(0.001)
## Minimum value for calculating a linear [code]x[/code] to hours.
const HOURS_MAX: int = 3600
## Minimum value for calculating a linear [code]x[/code] to minutes and seconds.
const SECS_MAX: int = 60

## Converts a linear value to the required amount to format it as hours.
func linear_to_hours(value: float) -> int: return int(value / HOURS_MAX)
## Converts a linear value to the required amount to format it as minutes.
func linear_to_minutes(value: float) -> int: return int(value / SECS_MAX) % SECS_MAX
## Converts a linear value to the required amount to format it as seconds.
func linear_to_seconds(value: float) -> float: return value - int(value / SECS_MAX) * SECS_MAX

## Maps a linear value [code]x[/code] (i.e: 0.5) to a logarithmic scale.
func linear_to_log(x: float) -> float: return exp(LOG_MINIMUM * (1 - x))
## Maps a logarithmic value [code]x[/code] (i.e: 0.001) back to a linear scale.
func log_to_linear(x: float) -> float: return 1 - (log(x) / LOG_MINIMUM)
#endregion

#region Strings
## Default Chart Difficulty.
const DEFAULT_DIFFICULTY: String = "normal"

## Which variations should be rebound to other variations.
const DEFAULT_VARIATION_BINDINGS: Dictionary[String, String] = {
	# Nightmare is just Erect Hard Mode so here you go.
	"nightmare": "erect",
}

### Returns "PAUSED" if the tree is paused.
func get_paused_string() -> String:
	return "PAUSED" if get_tree().paused else ""

## Returns a game mode string based on the integer given.[br]
## [code]1 = "STORY MODE"[/code][br]
## [code]2 = "FREEPLAY"[/code][br]
## [code]3 = "CHARTING"[/code]
func get_mode_string(game_mode: int) -> String:
	match game_mode:
		0: return "STORY MODE"
		1: return "FREEPLAY"
		2: return "CHARTING"
		_: return ""

## Formats a float to a digital clock string, like: 1:10:25[br]
func format_to_time(value: float, show_milliseconds: bool = false) -> String:
	var minutes: float = Global.linear_to_minutes(value)
	var seconds: float = Global.linear_to_seconds(value)
	var hours: int = Global.linear_to_hours(value)
	var formatter: String = "%2d:%02d" % [minutes, seconds]
	if hours != 0: # append hours if needed
		formatter += ":02d" % [hours, minutes, seconds]
	if show_milliseconds:
		formatter += ".%02d" % int((value - int(value)) * 1000)
	return formatter

## Gets the current weekday as a name
func get_weekday_string() -> String:
	var weekday: Time.Weekday = Time.get_date_dict_from_system().weekday
	match weekday:
		0: return "Sunday"
		1: return "Monday"
		2: return "Tuesday"
		3: return "Wednesday"
		4: return "Thursday"
		5: return "Friday"
		_: return "Unknown"

func separate_thousands(value: int, separator: String = ",") -> String:
	var vstr: String = str(abs(value))
	var prefix: String = "-" if value < 0 else ""
	# regex to insert a separator every 3 digits to the right
	var regex = RegEx.new()
	regex.compile("(\\d)(?=(\\d{3})+$)")
	vstr = regex.sub(vstr, "$1" + separator, true)
	return prefix + vstr

#endregion

#region Discord RPC
## Default App Client ID, for Discord RPC
const DISCORD_RPC_ID: int = 1328904269151338507
## Default Large Image that shows up on Discord.
const DISCORD_RPC_DEFAULT_LI: String = "default"
## Default assets for charts, used in case "assets.tres" is missing in the chart folder.
const DEFAULT_CHART_ASSETS: ChartAssets = preload("res://assets/resources/chart_assets.tres")
## Default Text that shows up when you hover over the large image on Discord.
const DISCORD_RPC_DEFAULT_LI_TEXT: String = ""

## Resets the state of the Discord RPC plugin back to the defaults.
func reset_discord() -> void:
	DiscordRPC.app_id = DISCORD_RPC_ID
	if not DiscordRPC.get_is_discord_working():
		push_warning("Discord Activity couldn't be updated. It could be that Discord isn't running!")
	update_discord_timestamps(0, 0)
	update_discord_images()

## Updates the details and state of Discord RPC.
func update_discord(state: String, details: String = "") -> void:
	if not DiscordRPC.get_is_discord_working(): return
	DiscordRPC.state = state
	if not details.is_empty(): DiscordRPC.details = details
	DiscordRPC.refresh()

## Updates the Discord RPC to add timestamps.
func update_discord_timestamps(start: int, end: int = -1) -> void:
	if not DiscordRPC.get_is_discord_working(): return
	DiscordRPC.start_timestamp = start
	if end > -1: DiscordRPC.end_timestamp = end
	DiscordRPC.refresh()

## Updates the images used in Discord RPC.
func update_discord_images(large: String = DISCORD_RPC_DEFAULT_LI, small: String = "", large_txt: String = DISCORD_RPC_DEFAULT_LI_TEXT, small_txt: String = "") -> void:
	if not DiscordRPC.get_is_discord_working(): return
	DiscordRPC.large_image = large
	DiscordRPC.large_image_text = large_txt
	if small and small.length() != 0:
		DiscordRPC.small_image = small
		DiscordRPC.small_image_text = small_txt
	DiscordRPC.refresh()
#endregion
