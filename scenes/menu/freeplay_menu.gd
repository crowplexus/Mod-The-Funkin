extends Node2D

# TODO: rewrite this.

## List of songs to display on-screen.
@export var songs: SongPlaylist

@onready var bg: Sprite2D = $"background"
@onready var score_text: Label = $"ui/score_text"
@onready var song_menu: Control = $"song_menu"
@onready var diff_text: Label = $"ui/score_text/diff_text"
@onready var tip_text: Label = $"ui/tip_text"

var selected: int = 0
var song_selected: int = 0
var difficulty: int = 1 # NORMAL
var lerp_score: float = 0

var selectables: Array[int] = []
var difficulty_name: String = Global.DEFAULT_DIFFICULTY
var display_score: Dictionary = Tally.empty_highscore()
var lists: Array[String] = []
var exiting: bool = false
var cursor_tween: Tween

func _ready() -> void:
	AudioServer.set_bus_effect_enabled(1, 0, false)
	var levels: PlaylistArray = load("uid://c4s0d4u5i34m3")
	for playlist: SongPlaylist in levels.list:
		load_from_playlist(playlist)
	levels.unreference()
	
	for song: SongItem in songs.list:
		if song.visible == 2 | 4: # Remove locked/hidden songs.
			var index: int = songs.list.find(song)
			songs.list.remove_at(index)
	
	Global.change_transition_style()
	song_menu.items.clear()
	song_menu.item_created.connect(func(item: Control) -> void:
		item.modulate.a = 0.6 if item.get_index() != selected else 1.0)
	Global.update_discord("Menus", "Selecting a Song in Freeplay")
	if get_tree().paused: get_tree().paused = false
	if Global.DEFAULT_SONG and not Conductor.is_music_playing():
		Conductor.set_music_stream(Global.DEFAULT_SONG)
		Conductor.bpm = Global.DEFAULT_SONG.bpm
		Conductor.play_music(0.0)
	Conductor.set_music_volume(0.7)
	reload_song_items()
	change_difficulty()

func _physics_process(delta: float) -> void:
	update_score_text(delta)

func _unhandled_input(_event: InputEvent) -> void:
	if exiting: return
	
	var accepting: bool = Input.is_action_just_pressed("ui_accept")
	var backing_out: bool = Input.is_action_just_released("ui_cancel")
	var axis_diff: int = int(Input.get_axis("ui_left", "ui_right"))
	var axis_song: int = int(Input.get_axis("ui_up", "ui_down"))
	
	if axis_diff != 0: change_difficulty(axis_diff)
	if axis_song != 0: change_selection(axis_song)
	if accepting:
		exiting = true
		Global.play_sfx(Global.resources.get_resource("confirm"))
		highlight_selected()
	if backing_out:
		exiting = true
		Global.change_scene("uid://c6hgxbdiwb6yn")

func go_to_gameplay() -> void:
	exiting = true
	Conductor.stop_music()
	Global.change_transition_style(&"alternate")
	Global.request_audio_fade(Conductor.bound_music, 0.0, 0.5)
	var parse: bool = true
	var selected_song: SongItem = songs.list[song_selected]
	if Gameplay.chart and Gameplay.chart.parsed_values.song_name == selected_song.folder:
		parse = false # same chart, don't parse what's already parsed.
	if parse: Gameplay.set_playlist([selected_song.folder], difficulty_name)
	if Gameplay.chart:
		Gameplay.chart.parsed_values.difficulties = selected_song.difficulties
	Gameplay.set_game_mode(Gameplay.GameMode.FREEPLAY)
	Global.change_scene("uid://cvf84mr6iepcs")

func highlight_selected() -> void:
	song_menu.active = false
	for song: CanvasItem in song_menu.get_children():
		if song.get_index() != selected:
			var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC).set_parallel(true)
			tween.tween_property(song, "position:x", -get_viewport_rect().size.x, 0.6)
			tween.tween_property(song, "self_modulate:a", 0.0, 0.7)
	Global.begin_flicker(song_menu.get_child(selected), 1.0, 0.04, true, true, go_to_gameplay)

## Changes the index of the selection cursor
func change_selection(next: int = 0) -> void:
	song_selected = wrapi(song_selected + next, selectables.front(), selectables.back() + 1)
	selected = wrapi(selected + next, 0, song_menu.get_child_count())
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	song_menu.focus_item(selected)
	change_difficulty()

## Changes the index of the difficulty cursor
func change_difficulty(next: int = 0) -> void:
	difficulty = wrapi(difficulty + next, 0, songs.list[song_selected].difficulties.size())
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	var diff: String = songs.list[song_selected].difficulties[difficulty]
	var tr_diff: String = tr("difficulty_%s" % diff.to_lower(), &"menus")
	diff_text.text = "\n« %s »" % [ tr_diff if not tr_diff.begins_with("difficulty_") else diff ]
	difficulty_name = diff
	refresh_display_score()

## Reloads every item in the menu.
func reload_song_items() -> void:
	selectables.clear()
	song_menu.items.clear()
	for song: SongItem in songs.list:
		selectables.append(songs.find(song))
		song_menu.items.append(song.name)
	song_selected = selectables.front()
	selected = selectables.find(song_selected)
	song_menu.regen_list()
	change_selection()

func load_from_playlist(list) -> void:
	if list is Array[SongItem] or list is SongPlaylist:
		var songs_array: Array[SongItem] = list.list if list is SongPlaylist else list # jank.
		for song: SongItem in songs_array:
			var add_next: bool = true # workaround to not add duplicte songs
			for local_song: SongItem in songs.list:
				if song.name == local_song.name and song.folder == local_song.folder:
					#print_debug("duplicate song found ", song.name)
					add_next = false
					continue
			if add_next:
				#print_debug("added ", song.name, " to local freeplay list")
				songs.list.append(song)
	else:
		print_debug("Playlist provided must be a Array[SongItem] or SongPlaylist.")

func refresh_display_score() -> void:
	if Tally.use_epics != Global.settings.use_epics:
		Tally.use_epics = Global.settings.use_epics
	var song: String = songs.list[song_selected].folder
	var diff: String = songs.list[song_selected].difficulties[difficulty]
	display_score = Tally.get_record(song, diff)

func update_score_text(delta: float) -> void:
	if score_text and display_score and "score" in display_score:
		var lerp_value: float = clamp(delta * 5.0, 0.0, 1.0)
		lerp_score = lerp(lerp_score, float(display_score.score), lerp_value) # placeholder
		if abs(lerp_score - display_score.score) < 0.01:
			lerp_score = display_score.score
		score_text.text = "HIGH SCORE: %s" % Global.separate_thousands(int(lerp_score))
