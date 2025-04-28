extends Node

const TRANSITIONS: Dictionary[String, PackedScene] = {
	"default": preload("uid://dmkymcq7pnoa5"),
}
var current_transition: StringName = &"default"

#region Node Tree
@onready var bgm: AudioStreamPlayer = $"%background_music"
@onready var sfx: Node = $"%sound_effects"
@onready var resources: ResourcePreloader = $"%resource_preloader"
@onready var transition: CanvasLayer = $"%transition_layer"

var previous_scene_path: String = "uid://c5qnedjs8xhcw"
var _was_paused: bool = false
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
	if event.pressed and not event.is_echo():
		if event.is_action("fullscreen"):
			var is_full: bool = get_window().mode == Window.Mode.MODE_FULLSCREEN
			get_window().mode = Window.MODE_WINDOWED if is_full else Window.MODE_FULLSCREEN
		if OS.is_debug_build() and event.keycode == KEY_P:
			get_tree().paused = not get_tree().paused

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT when settings.auto_pause:
			_was_paused = get_tree().paused
			get_tree().paused = true
		NOTIFICATION_APPLICATION_FOCUS_IN when settings.auto_pause:
			get_tree().paused = _was_paused
		NOTIFICATION_WM_CLOSE_REQUEST:
			settings.save_settings()

#endregion

#region Utils

func change_transition_style(next: StringName = &"default") -> void:
	if next in TRANSITIONS: current_transition = next

func play_transition() -> Control:
	var trans: Control = TRANSITIONS[current_transition].instantiate()
	trans.finished.connect(func() -> void: trans.queue_free())
	transition.add_child(trans)
	trans.play()
	return trans

func reload_scene(immediate: bool = false) -> void:
	var transit: bool = not immediate and not settings.skip_transitions
	if not current_transition in TRANSITIONS:
		transit = false
	if transit:
		var trans: = play_transition()
		await get_tree().create_timer(trans.duration * 0.35).timeout
	get_tree().reload_current_scene()
	if transit: play_transition()

func rewind_scene(immediate: bool = false) -> void:
	change_scene(previous_scene_path, immediate)

func change_scene(next, immediate: bool = false) -> void:
	if is_inside_tree() and next != previous_scene_path:
		previous_scene_path = get_tree().current_scene.scene_file_path
	var transit: bool = not immediate and not settings.skip_transitions
	if not current_transition in TRANSITIONS:
		transit = false
	if transit:
		var trans: = play_transition()
		await get_tree().create_timer(trans.duration * 0.35).timeout
	if next is String: get_tree().change_scene_to_file(next)
	elif next is PackedScene: get_tree().change_scene_to_packed(next)

func begin_flicker(node: CanvasItem, duration: float = 1.0, interval: float = 0.04,
	end_vis: bool = false, force: bool = false, finish_callable: Callable = func() -> void: pass) -> void:
	####
	if node == null: return
	if force:
		node.modulate.a = 1.0
		node.self_modulate.a = 1.0
		node.visible = true
	var twn: Tween = create_tween()
	twn.set_loops(int(duration/interval))
	twn.bind_node(node)
	twn.finished.connect(func() -> void:
		node.visible = end_vis
		if finish_callable != null:
			finish_callable.call()
	)
	twn.tween_callback(func() -> void:
		node.visible = not node.visible
	).set_delay(interval)
#endregion

#region Music
var music_fade_tween: Tween

## Activates a volume fade tween in [code]player: AudioStreamPlayer[/code].
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
## [code]1 = "Story Mode"[/code][br]
## [code]2 = "Freeplay"[/code][br]
## [code]3 = "Charting"[/code][br]
## Anything else will return [code]"Unknown"[/code]
func get_mode_string(game_mode: int) -> String:
	match game_mode:
		0: return "Story Mode"
		1: return "Freeplay"
		2: return "Charting"
		_: return "Unknown"

## Formats a float to a digital clock string, example: 1:10:25[br]
func format_to_time(value: float, show_milliseconds: bool = false) -> String:
	var minutes: float = Global.linear_to_minutes(value)
	var seconds: float = Global.linear_to_seconds(value)
	var hours: int = Global.linear_to_hours(value)
	var content: Array = [hours, minutes, seconds]
	if hours <= 0: content.remove_at(0)
	var time_string: String = "%2d:%02d"
	if hours > 0: time_string += ":%02d"
	if show_milliseconds:
		time_string += ".%03d"
		content.append(int((value - int(value)) * 1000))
	var result: String = time_string.dedent() % content
	return result.dedent()

## Gets the current weekday as a name.
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

## Formats an integer to separate the thousand value with [code]separator[/code].
func separate_thousands(value: int, separator: String = ",") -> String:
	var vstr: String = str(abs(value))
	var prefix: String = "-" if sign(value) == -1 else ""
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
const DEFAULT_CHART_ASSETS: ChartAssets = preload("uid://cp25ehrc4xvy2")
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
