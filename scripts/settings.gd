class_name Settings extends Resource

const _IGNORED_PROPERTIES: Array[String] = ["resource_local_to_scene", "resource_scene_unique_id", "resource_name", "resource_path", "script"]

## Defines the Master Volume of the game.
var master_volume: int = 30
## Shortcut setting for muting the whole game.
var master_mute: bool = false
## Setting to hide the fps counter.
var hide_fps_info: bool = false
## Alternates between in-game scroll directions.
@export_enum("Up:0","Down:1")
var scroll: int = 0
## User-defined controls, with primary and secondary keybinds for actions.
@export var controls: Dictionary[String, PackedStringArray] = {
	# I don't really need to do arrays this way but its funny.
	## -- Note Keybinds --
	"note_left" : "D,Left".split(","),
	"note_down" : "F,Down".split(","),
	"note_up"   : "J,Up".split(","),
	"note_right": "K,Right".split(","),
	## -- Extra Keybinds --
	"volume_up": "Equal,K Add".split(","),
	"volume_down": "Minus,Kp Subtract".split(","),
	"volume_mute": "0,Kp 0".split(","),
}
## Prevents inputs from punishing you if you press keys when there's no notes to hit.
@export_enum("Disabled:0", "When in silence:1", "Enabled:2")
var ghost_tapping: int = 1
## Defines the maximum timing window for a note to be hittable.
@export var max_hit_window: float = 0.18 # 180ms
## Enables a 5th judgement not originally present in the game.
@export var use_epics: bool = true
## Defines an offset for music synching, delays note spawning.[br]
## This is set to an amount of seconds.
@export var note_offset: float = 0.0

## How fast should the notes be? affected by [code]Settings.note_speed_mode[/code]
@export var note_speed: float = 1.0
## How should notes deal with scroll speed?
@export_enum("Default:0", "Multiply Chart's:1", "User-Constant:2", "BPM-Based:3")
var note_speed_mode: int = 0
## How fast/slow should the song be when playing.
@export var playback_rate: float = 1.0
## Disables inputs and makes the player hit notes automatically.
@export var botplay_mode: bool = false
## Makes the song loop instead of end when playing.
@export var loop_game_music: bool = false

## You know what a framerate is, right?
@export var framerate: int = 120
## Decides if the game should pause if the window loses focus.
@export var auto_pause: bool = true
## Changes how framerate updates in the engine.[br][br]
## Capped will use whatever value is in the framerate setting.
## Unlimited won't use any values at all, instead, the framerate will be updated based on hardware limits.[br]
## Mailbox locks the framerate to your monitor's refresh rate, which may help reducing screen tearing.[br]
## Adaptive adjusts the framerate if it's high, or if it's dropping, essentially balacing the drawbacks of VSync with the benefits.
@export_enum("Capped:0", "Unlimited:1", "Mailbox:2", "Adaptive:3")
var vsync_mode: int = 0

## Defines the intensity of the Camera Bump.
@export var bump_intensity: int = 100:
	set(new_bi): bump_intensity = clampi(new_bi, 0, 100)
## Defines the intensity of the HUD Bump.
@export var hud_bump_intensity: int = 100:
	set(new_bi): hud_bump_intensity = clampi(new_bi, 0, 100)

## Select a HUD style, or leave "Default" to let the songs decide.
@export_enum("Default", "Advanced", "Classic", "Psych")
var hud_style: String = "Default"
## Choose how the game deals with note colours.
@export_enum("Column:0", "Judgement:1", "Quant:2")
var note_color_mode: int = 0
## Makes it so the judgements and combo will stack on top of themselves.[br]
## Disable to only have a single sprite for each judgement and combo at a time.
@export var combo_stacking: bool = true
## Changes the UI elements and dialogue language.
@export_enum("en")
var language: String = "auto": # "auto" means get OS locale
	set(new_lang): language = new_lang.to_snake_case()
## Defines the transition type, or disables it altogether.
@export_enum("None:0", "Default:1", "Wipe:2")#, "Sticker:3")
var transition_style: int = 1:
	set(new_trans):
		transition_style = new_trans
		match transition_style:
			2: Global.current_transition = &"default"
			#3: Global.current_transition = &"sticker"
## Defines how opaque should the note impact effect be when hitting judgements that display it.
@export var note_splash_alpha: int = 60:
	set(new_alpha): note_splash_alpha = clampi(new_alpha, 0, 100)
## Defines how opaque should the health bar be for HUDs that have it.
@export var health_bar_alpha: int = 100:
	set(new_alpha): health_bar_alpha = clampi(new_alpha, 0, 100)
## Simplifies the in-game pop ups to make them easier to see (maybe less obnoxious).
@export var simplify_popups: bool = false
## Changes the style of any present HUD timers.
@export_enum("Hidden:0", "Time Left:1", "Time Elapsed:2", "Song Name:3", "Elapsed / Total:4")
var timer_style: int = 0

var skip_transitions: bool:
	get: return transition_style < 0

func _init(use_defaults: bool = false) -> void:
	if not use_defaults: # not a "defaults-only" instance
		reload_custom_settings()

## Upadtes every setting that really needs it.
func update_all() -> void:
	for blah: String in get_settings().keys():
		match blah:
			"framerate": update_framerate()
			"vsync_mode": update_vsync_mode()
			"master_volume": update_master_volume()
			"controls": reload_controls()
			"language": reload_locale()

## Reloads the current display language.
func reload_locale() -> void:
	var list: = TranslationServer.get_loaded_locales()
	var new_lang: String = "en"
	if language == "auto": new_lang = OS.get_locale_language()
	if new_lang in list: language = new_lang
	TranslationServer.set_locale(new_lang)
	language = new_lang

## Reloads all of the bound controls.
func reload_controls() ->  void:
	var ckeys: Array[String] = controls.keys()
	for action: String in ckeys:
		if InputMap.has_action(action):
			for key: InputEvent in InputMap.action_get_events(action):
				if not key or not InputMap.action_has_event(action, key): continue
				InputMap.action_erase_event(action, key)
				key.unreference()
		var actions: PackedStringArray = controls[action]
		for i: String in actions:
			var new_action: InputEventKey = InputEventKey.new()
			new_action.set_keycode(OS.find_keycode_from_string(i.to_lower()))
			#var kcd: Key = OS.find_keycode_from_string(i.to_lower())
			#print_debug(action, " set to ", OS.get_keycode_string(kcd))
			InputMap.action_add_event(action, new_action)

## Updates the master volume and mute.
func update_master_volume() -> void:
	master_volume = clampi(master_volume, 0, 100)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume * 0.01))
	AudioServer.set_bus_mute(0, master_mute)

## Updates the Engine's max framerate.
func update_framerate() -> void:
	update_vsync_mode()
	Engine.max_fps = clampi(framerate, 30, 360)
	framerate = Engine.max_fps

## Updates the Engine's Display Server to enable/disable VSync.
func update_vsync_mode() -> void:
	match vsync_mode:
		0: # Capped
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			Engine.max_fps = framerate
		1: # Uncapped
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			Engine.max_fps = 0
		2: # Mailbox
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_MAILBOX)
		3: # Adaptive
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)

## Reloads your own custom settings (if any).
func reload_custom_settings() -> void:
	if not ResourceLoader.exists("user://mtf_settings.tres"):
		return
	var custom_settings: Settings = load("user://mtf_settings.tres")
	if custom_settings:
		for key: String in get_settings().keys():
			var setting: Variant = get(key)
			if setting != custom_settings.get(key):
				if setting is Dictionary:
					for dict_key: String in setting.keys():
						var custom_dict: Dictionary = custom_settings.get(key)
						if not dict_key in custom_dict: # set any missing keys to the custom dictionary.
							custom_dict.set(dict_key, setting.get(dict_key))
						# set the dictionary to the custom one.
						set(key, custom_settings.get(key))
				else:
					set(key, custom_settings.get(key))
		custom_settings.unreference()

## Grabs all the settings (not including constant properties)
func get_settings() -> Dictionary:
	var props: Dictionary[String, Variant] = {}
	for prop in get_property_list():
		if not _IGNORED_PROPERTIES.has(prop.name) and get(prop.name) != null:
			props[prop.name] = get(prop.name)
	return props

## Saves the settings to a file in the user folder[br]
## usually in %APPDATA%\Godot\app_userdata\ or /home/user/.local/share/godot/app_userdata/
func save_settings() -> void:
	ResourceSaver.save(self, "user://mtf_settings.tres", ResourceSaver.FLAG_OMIT_EDITOR_PROPERTIES)
