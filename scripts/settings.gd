class_name Settings
extends Resource

const _IGNORED_PROPERTIES: Array[String] = ["resource_local_to_scene", "resource_scene_unique_id", "resource_name", "resource_path", "script"]

var _was_uncapped: bool = false

## Defines the Master Volume of the game.
var master_volume: int = 30
## Shortcut setting for muting the whole game.
var master_mute: bool = false
## Alternates between in-game scroll directions.
@export_enum("Up:0","Down:1")
var scroll: int = 0
## Defines note keybinds.
@export var keybinds: Array[PackedStringArray] = [
	"DFJK".split(""), # Primary Keybinds (Player 1)
	"Left,Down,Up,Right".split(",") # Secondary Keybinds (Player 2)
]
## Prevents inputs from punishing you if you press keys when there's no notes to hit.
@export var ghost_tapping: bool = true
## Defines the maximum timing window for a note to be hittable.
@export var max_hit_window: float = 0.18 # 180ms
## Enables a 5th judgement not originally present in the game.
@export var use_epics: bool = true
## Defines an offset for music synching, delays note spawning.[br]
## This is set to an amount of seconds.
@export var note_offset: float = 0.0
## You know what a framerate is, right?
@export var framerate: int = 120
## Decides if the game should pause if the window loses focus.
@export var auto_pause: bool = true
## Locks framerate to your monitor's refresh rate[br]
## May help reducing screen tearing.
@export var vsync: bool = false
## Defines the intensity of the Camera Bump.
@export var bump_intensity: int = 100:
	set(new_bi): bump_intensity = clampi(new_bi, 0, 100)
## Defines the intensity of the HUD Bump.
@export var hud_bump_intensity: int = 100:
	set(new_bi): hud_bump_intensity = clampi(new_bi, 0, 100)
## Select a HUD style, or leave "Default" to let the songs decide.
@export_enum("Default", "Classic", "Advanced")
var hud_style: String = "Default"
## Changes the UI elements and dialogue language.
@export_enum("en", "es", "pt", "mk") # English, Spanish, Portuguese, Macedonian
var language: String = "auto" # "auto" means get OS locale

func _init(use_defaults: bool = false) -> void:
	if not use_defaults: # not a "defaults-only" instance
		reload_custom_settings()

## Reloads the current display language.
func reload_locale() -> void:
	var list: = TranslationServer.get_loaded_locales()
	if language == "auto":
		var os_lang: String = OS.get_locale_language()
		if os_lang in list: TranslationServer.set_locale(os_lang)
		else: TranslationServer.set_locale("en")
	else:
		TranslationServer.set_locale(language)

## Reloads the note keybinds.
func reload_keybinds() -> void:
	const NOTE_KEYBINDS: Array[String] = ["note_left", "note_down", "note_up", "note_right"]
	for action: String in NOTE_KEYBINDS:
		if InputMap.has_action(action):
			for key: InputEvent in InputMap.action_get_events(action):
				if not key or not InputMap.action_has_event(action, key): continue
				InputMap.action_erase_event(action, key)
				key.unreference()
	for i: int in keybinds.size(): # 2 Players
		for j: int in keybinds[i].size(): # 4 keys
			var action: String = NOTE_KEYBINDS[j]
			var keystr: String = keybinds[i][j].to_lower()
			var new_event: InputEventKey = InputEventKey.new()
			new_event.set_keycode(OS.find_keycode_from_string(keystr))
			InputMap.action_add_event(action, new_event)
			#print_debug(action, " set to ", OS.find_keycode_from_string(keystr))

## Updates the master volume and mute.
func update_master_volume() -> void:
	master_volume = clampi(master_volume, 0, 100)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume * 0.01))
	AudioServer.set_bus_mute(0, master_mute)

## Updates the Engine's max framerate.
func update_framerate() -> void:
	if framerate == 0 and _was_uncapped: _was_uncapped = false
	if not _was_uncapped and framerate < 30 or framerate > 360:
		_was_uncapped = true
		Engine.max_fps = 0
		framerate = 0
		return
	Engine.max_fps = clampi(framerate, 30, 360)
	framerate = Engine.max_fps

## Updates the Engine's Display Server to enable/disable VSync.
func update_vsync() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE if vsync else DisplayServer.VSYNC_DISABLED)

## Reloads your own custom settings (if any).
func reload_custom_settings() -> void:
	if not ResourceLoader.exists("user://mtf_settings.tres"):
		return
	var custom_settings: Settings = load("user://mtf_settings.tres")
	if custom_settings:
		for key: String in get_settings().keys():
			if get(key) != custom_settings.get(key):
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
