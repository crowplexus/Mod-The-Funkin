extends Node2D

# TODO: rewrite this.

const TIP_BUTTONS: String = "Push Q/E to Switch Categories\nPush R to Select a Random Song"

## List of songs to display on-screen.
@export var songs: SongPlaylist = preload("uid://cfxu4hd3spw4u").duplicate()

@onready var bg: Sprite2D = $"background"

@onready var score_text: Label = $"ui/score_text"
@onready var song_menu: Control = $"song_menu"
@onready var diff_text: Label = $"ui/score_text/diff_text"
@onready var tip_text: Label = $"ui/tip_text"

var selected: int = 0
var song_selected: int = 0
var current_list: int = 0 # Ungrouped / Main Levels
var difficulty: int = 1 # NORMAL
var lerp_score: float = 0

var selectables: Array[int] = []
var _harcoded_entries: Array[String] = []
var difficulty_name: String = Global.DEFAULT_DIFFICULTY
var display_score: Dictionary = Tally.empty_highscore()
var lists: Array[String] = []
var exiting: bool = false
var cursor_tween: Tween

func _ready() -> void:
	_harcoded_entries.append_array(song_menu.items)
	song_menu.item_created.connect(func(item: Control) -> void:
		item.modulate.a = 0.6 if item.get_index() != selected else 1.0)
	for i: SongItem in songs.list:
		if not i.list_name in lists:
			lists.append(i.list_name)
			if not i.shown_in_freeplay:
				var index: int = songs.list.find(i)
				songs.list.remove_at(index)
	Global.update_discord("Menus", "Selecting a Song in Freeplay")
	if get_tree().paused: get_tree().paused = false
	if Global.DEFAULT_SONG and not Global.bgm.playing:
		Global.play_bgm(Global.DEFAULT_SONG, 0.7)
		Conductor.bpm = Global.DEFAULT_SONG.bpm
	change_category()
	change_difficulty()

func _process(delta: float) -> void:
	var lerp_value: float = clamp(delta * 9.6, 0.0, 1.0)
	song_menu.position_lerp = lerp_value
	
	# update score lerp and shit
	if score_text and display_score and "score" in display_score:
		lerp_score = lerp(lerp_score, float(display_score.score), lerp_value) # placeholder
		if abs(lerp_score - display_score.score) < 0.01:
			lerp_score = display_score.score
		score_text.text = "HIGH SCORE: %s" % Global.separate_thousands(int(lerp_score))

func _unhandled_input(_event: InputEvent) -> void:
	if exiting: return
	
	var accepting: bool = Input.is_action_just_pressed("ui_accept")
	var backing_out: bool = Input.is_action_just_released("ui_cancel")
	var axis_diff: int = int(Input.get_axis("ui_left", "ui_right"))
	var axis_song: int = int(Input.get_axis("ui_up", "ui_down"))
	
	if axis_diff != 0: change_difficulty(axis_diff)
	if axis_song != 0: change_selection(axis_song)
	if accepting:
		Global.play_sfx(Global.resources.get_resource("confirm"))
		highlight_selected()
	if backing_out:
		exiting = true
		Global.change_scene("uid://c6hgxbdiwb6yn")

func go_to_gameplay() -> void:
	exiting = true
	Global.request_audio_fade(Global.bgm, 0.0, 0.5)
	var song_to_pick: SongItem = songs.list[song_selected]
	var parse: bool = true
	if Gameplay.chart and Gameplay.chart.parsed_values.song_name == song_to_pick.folder:
		parse = false # same chart, don't parse what's already parsed.
	if parse: Gameplay.chart = Chart.detect_and_parse(song_to_pick.folder, difficulty_name)
	if Gameplay.chart:
		Gameplay.chart.parsed_values.difficulties = song_to_pick.difficulties
	Global.change_scene("uid://cvf84mr6iepcs")

func highlight_selected() -> void:
	for song: CanvasItem in song_menu.get_children():
		if song.get_index() != selected:
			var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC).set_parallel(true)
			tween.tween_property(song, "position:x", -get_viewport_rect().size.x, 0.6)
			tween.tween_property(song, "modulate:a", 0.0, 0.5)
	Global.begin_flicker(song_menu.get_child(selected), 1.0, 0.04, true, true, go_to_gameplay)

## Changes the index of the selection cursor
func change_selection(next: int = 0) -> void:
	var item: Control = song_menu.get_child(selected)
	
	song_selected = wrapi(song_selected + next, selectables.front(), selectables.back() + 1)
	selected = wrapi(selected + next, 0, song_menu.get_child_count())
	refresh_display_score()
	
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	if item: item.modulate.a = 0.6
	item = song_menu.get_child(selected)
	if item: item.modulate.a = 1.0
	song_menu.target_offset = selected
	if songs.list[song_selected].difficulties.find(difficulty_name) == -1:
		change_difficulty()

## Changes the index of the difficulty cursor
func change_difficulty(next: int = 0) -> void:
	difficulty = wrapi(difficulty + next, 0, songs.list[song_selected].difficulties.size())
	refresh_display_score()
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	var diff: String = songs.list[song_selected].difficulties[difficulty]
	var tr_diff: String = tr("difficulty_%s" % diff.to_lower(), &"menus")
	diff_text.text = "\n« %s »" % [ tr_diff if not tr_diff.begins_with("difficulty_") else diff ]
	difficulty_name = diff

## Changes the index of the current category
func change_category(next: int = 0) -> void:
	current_list = wrapi(current_list + next, 0, lists.size())
	#tip_text.text = "[ %s ]\n%s" % [ lists[current_list], TIP_BUTTONS ]
	if next != 0: Global.play_sfx(Global.resources.get_resource("fav"))
	reload_song_items()

## Reloads every item in the menu.
func reload_song_items() -> void:
	selectables.clear()
	song_menu.items.clear()
	# in case your hardcode any buttons and whatnot.
	song_menu.items.append_array(_harcoded_entries)
	for song: SongItem in songs.list:
		if not song or (not song.list_name.is_empty() and song.list_name != lists[current_list]):
			continue
		selectables.append(songs.list.find(song))
		song_menu.items.append(song.name)
	song_selected = selectables.front()
	selected = selectables.find(song_selected)
	song_menu.regen_list()
	change_selection()

func refresh_display_score() -> void:
	if Tally.use_epics != Global.settings.use_epics:
		Tally.use_epics = Global.settings.use_epics
	var song: String = songs.list[song_selected].folder
	var diff: String = songs.list[song_selected].difficulties[difficulty]
	display_score = Tally.get_record(song, diff)
