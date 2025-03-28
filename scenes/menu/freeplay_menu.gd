extends Node2D

# TODO: rewrite this.

## Song to play if the audio file for the hovered one couldn't be found.
@export var default_song: AudioStream = preload("res://assets/music/freeplayRandom.ogg")
## List of songs to display on-screen.
@export var songs: SongList = preload("res://assets/default/song_list.tres")

@onready var song_container: Control = $"song_container"
@onready var random_template = $"song_container/random"
@onready var bg: Sprite2D = $"background"

@onready var diff_text: Label = $"score_bg/diff_text"

var cursor_tween: Tween
var selected: int = 0
var difficulty: int = 1 # NORMAL
var difficulty_name: String = Global.DEFAULT_DIFFICULTY
var exiting: bool = false

func _ready() -> void:
	if get_tree().paused: get_tree().paused = false
	Global.play_bgm(default_song, 0.7)
	Conductor.bpm = default_song.bpm
	#Global.request_audio_fade(Global.bgm, 1.0, 0.3)
	song_container.get_child(0).text = "Random"
	for song: SongItem in songs.list:
		#var i: int = songs.list.find(song)
		var item: Control = random_template.duplicate()
		song_container.add_child(item)
		item.name = song.folder
		item.text = song.name
		item.song = song
	for i: int in song_container.get_child_count(): # offset here
		var item: Control = song_container.get_child(i)
		item.position.y += (item.size.y + 5) * i
		item.label.modulate.a = 0.6
		#if i == 0: item.position.y += 5
	if song_container.get_child_count() != 1:
		selected = 1
	change_selection()
	change_difficulty()

func _process(_delta: float) -> void:
	pass
	#for item: Control in song_container.get_children():
	#	var index: int = item.get_index()
	#	#var scaled_y: float = remap(index, 0, 1, 0, 1.3)
	#	item.position.x = lerpf(item.position.x, item.size.x + (60 * sin(index - selected)), exp(delta * 10))
	#	item.position.y = lerpf(item.position.y, index * (((item.size.y * item.scale.y) / get_viewport_rect().size.y) + 10), exp(delta * 80))

func _unhandled_input(event: InputEvent) -> void:
	if exiting: return
	var accepting: bool = Input.is_action_just_pressed("ui_accept")
	var backing_out: bool = Input.is_action_just_released("ui_cancel")
	
	# touch / mouse controls #
	var selecting: bool = false
	if event is InputEventMouseMotion or event is InputEventScreenTouch:
		for song: Control in song_container.get_children():
			var index: int = song.get_index()
			if selected != index and event.global_position == song.label.global_position and event.button_mask == MOUSE_BUTTON_LEFT:
				selecting = true
				selected = wrapi(index, 0, song_container.get_child_count())
				print_debug("selected ", index, " from mouse position")
				break
	if event is InputEventMouseButton and not selecting:
		match event.button_mask:
			MOUSE_BUTTON_LEFT when event.double_click: accepting = true
			MOUSE_BUTTON_RIGHT: backing_out = true
	selecting = false
	# keyboard controls #
	var axis: int = floori(Input.get_axis("ui_up", "ui_down"))
	var axis_diff: int = floori(Input.get_axis("ui_left", "ui_right"))
	if axis_diff != 0: change_difficulty(axis_diff)
	if axis != 0: change_selection(axis)
	if accepting:
		Global.request_audio_fade(Global.bgm, 0.0, 0.5)
		var song_to_pick: = songs.list[selected - 1]
		if selected == 0: song_to_pick = songs.pick_random()
		Gameplay.chart = Chart.detect_and_parse(song_to_pick.folder, difficulty_name)
		Global.change_scene("res://scenes/gameplay/gameplay.tscn")
	if backing_out:
		Global.change_scene("res://scenes/menu/lobby.tscn")

## Changes the index of the selection cursor
func change_selection(next: int = 0) -> void:
	var item: Control = song_container.get_child(selected)
	selected = wrapi(selected + next, 0, song_container.get_child_count())
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	if item: item.label.modulate.a = 0.6
	item = song_container.get_child(selected)
	item.label.modulate.a = 1.0
	if songs.list[selected - 1].difficulties.find(difficulty_name) == -1:
		change_difficulty()

## Changes the index of the difficulty cursor
func change_difficulty(next: int = 0) -> void:
	difficulty = wrapi(difficulty + next, 0, songs.list[selected - 1].difficulties.size())
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	var diff: String = songs.list[selected - 1].difficulties[difficulty]
	diff_text.text = "< %s >" % diff
	difficulty_name = diff
