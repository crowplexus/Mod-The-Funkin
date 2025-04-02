extends Node2D

# TODO: rewrite this.

const TIP_BUTTONS: String = "Push Q/E to Switch Categories\nPush R to Select a Random Song"

## Song to play if the audio file for the hovered one couldn't be found.
@export var default_song: AudioStream = preload("res://assets/music/freeplayRandom.ogg")
## List of songs to display on-screen.
@export var songs: SongList = preload("res://assets/default/song_list.tres")

@onready var song_container: Control = $"song_container"
@onready var item_template: Control = $"song_container/random".duplicate()
@onready var bg: Sprite2D = $"background"

@onready var diff_text: Label = $"ui/diff_text"
@onready var tip_text: Label = $"ui/tip_text"

var selected: int = 0
var song_selected: int = 0
var selectables: Array[int] = []
var difficulty: int = 1 # NORMAL
var current_list: int = 0 # Ungrouped / Main Levels
var difficulty_name: String = Global.DEFAULT_DIFFICULTY
var lists: Array[String] = []
var exiting: bool = false
var cursor_tween: Tween

func _ready() -> void:
	$"song_container/random".queue_free()
	for i: SongItem in songs.list:
		if not i.list_name in lists:
			lists.append(i.list_name)
	Global.update_discord("Menus", "Selecting a Song in Freeplay")
	if get_tree().paused: get_tree().paused = false
	Global.play_bgm(default_song, 0.7)
	Conductor.bpm = default_song.bpm
	#Global.request_audio_fade(Global.bgm, 1.0, 0.3)
	change_category()
	change_difficulty()

func _process(delta: float) -> void:
	for item: Control in song_container.get_children():
		var index: int = item.get_index()
		var scaled_y: float = remap(index, 0, 1, 0, 1.3)
		#item.position.x = lerpf(item.position.x, item.size.x + (60 * sin(index - selected)), exp(delta * 10))
		item.position.y = lerpf(item.position.y, index * ((650 * (item.size.y * item.scale.y) / get_viewport_rect().size.y) + 10), 0.15)

func _unhandled_input(event: InputEvent) -> void:
	if exiting: return
	
	var accepting: bool = Input.is_action_just_pressed("ui_accept")
	var backing_out: bool = Input.is_action_just_released("ui_cancel")
	var axis_diff: int = int(Input.get_axis("ui_left", "ui_right"))
	var axis: int = int(Input.get_axis("ui_up", "ui_down"))
	
	if axis_diff != 0: change_difficulty(axis_diff)
	if axis != 0: change_selection(axis)
	if not event.is_echo() and event.pressed:
		match event.keycode:
			KEY_Q: change_category(-1)
			KEY_E: change_category(1)
	
	if accepting:
		go_to_gameplay()
	if backing_out:
		exiting = true
		Global.change_scene("res://scenes/menu/lobby.tscn")

func go_to_gameplay() -> void:
	exiting = true
	Global.request_audio_fade(Global.bgm, 0.0, 0.5)
	var song_to_pick: SongItem = songs.list[song_selected]
	Gameplay.chart = Chart.detect_and_parse(song_to_pick.folder, difficulty_name)
	if Gameplay.chart:
		Gameplay.chart.parsed_values.difficulties = song_to_pick.difficulties
	Global.change_scene("res://scenes/gameplay/gameplay.tscn")

## Changes the index of the selection cursor
func change_selection(next: int = 0) -> void:
	var item: Control = song_container.get_child(selected)
	
	song_selected = wrapi(song_selected + next, selectables.front(), selectables.back() + 1)
	selected = wrapi(selected + next, 0, song_container.get_child_count())

	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	if item: item.label.modulate.a = 0.6
	item = song_container.get_child(selected)
	item.label.modulate.a = 1.0
	if songs.list[song_selected].difficulties.find(difficulty_name) == -1:
		change_difficulty()

## Changes the index of the difficulty cursor
func change_difficulty(next: int = 0) -> void:
	difficulty = wrapi(difficulty + next, 0, songs.list[song_selected].difficulties.size())
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	var diff: String = songs.list[song_selected].difficulties[difficulty]
	var tr_diff: String = tr("difficulty_%s" % diff.to_lower(), &"menus")
	diff_text.text = "< %s >" % tr_diff if not tr_diff.begins_with("difficulty_") else diff
	difficulty_name = diff

## Changes the index of the current category
func change_category(next: int = 0) -> void:
	current_list = wrapi(current_list + next, 0, lists.size())
	tip_text.text = "[ %s ]\n%s" % [ lists[current_list], TIP_BUTTONS ]
	if next != 0: Global.play_sfx(Global.resources.get_resource("fav"))
	reload_song_items()

## Reloads every item in the menu.
func reload_song_items() -> void:
	selectables.clear()
	for i: Control in song_container.get_children(): i.queue_free()
	for song: SongItem in songs.list:
		if not song or (not song.list_name.is_empty() and song.list_name != lists[current_list]):
			continue
		var i: int = songs.list.find(song)
		var item: Control = item_template.duplicate()
		song_container.add_child(item)
		item.name = song.folder
		item.text = song.name
		selectables.append(i)
		item.song = song
	song_selected = selectables.front()
	selected = selectables.find(song_selected)
	for i: int in song_container.get_child_count(): # offset here
		var item: Control = song_container.get_child(i)
		item.label.modulate.a = 1.0 if i == song_selected else 0.6
		item.position.y += (item.size.y + 5) * i
	change_selection()
