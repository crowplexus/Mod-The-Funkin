extends Node2D

@onready var yellow: ColorRect = $"yellow"
@onready var titles: BoxContainer = $"level_ui/titles"
@onready var tagline: Label = $"black/tagline"
@onready var tracks: Label = $"level_ui/tracks"

@onready var left_arrow_sprite: Sprite2D = $"level_ui/difficulty/arrow_l"
@onready var difficulty_sprite: Sprite2D = $"level_ui/difficulty"
@onready var right_arrow_sprite: Sprite2D = $level_ui/"difficulty/arrow_r"

@export var levels: PlaylistArray

var title_positions: Array[Vector2] = []
var title_separation: float = 40.0
var initial_y_diff: float = 80.0

var yellow_tween: Tween
var exiting: bool = false

var selected: int = 0
var difficulty: int = 1 # Normal.
var difficulty_name: StringName = Global.DEFAULT_DIFFICULTY
var difficulty_textures: Array[Texture2D] = []
var difficulty_tween: Tween
var arrow_tween: Tween

var current_level: SongPlaylist:
	get: return levels.list[selected]

func _ready() -> void:
	get_tree().paused = false
	reset_music()
	# cache difficulty textures
	var diffs_pushed: Array[String] = []
	for level: SongPlaylist in levels.list:
		for diff: String in level.campaign_difficulties:
			if diffs_pushed.has(diff):
				continue
			var tex_path: String = "res://assets/ui/menu/story/difficulties/" + diff.to_snake_case() + ".png"
			#var is_animated: bool = ResourceLoader.exists(tex_path.replace(".png", ".xml")) or ResourceLoader.exists(tex_path.replace(".png", ".res")) # fuck you
			if ResourceLoader.exists(tex_path):# and not is_animated:
				difficulty_textures.append(load(tex_path))
			else:
				difficulty_textures.append(null)
			diffs_pushed.append(diff)
	
	initial_y_diff = difficulty_sprite.position.y
	title_separation = titles.get_theme_constant("separation")
	create_titles()
	change_selection()

func _process(delta: float) -> void:
	var scroll_lerp: float = clamp(delta * 10.2, 0.0, 1.0)
	for i: int in titles.get_child_count():
		var hm: TextureRect = titles.get_child(i)
		var w: float = hm.texture.get_width() if hm.texture else 480
		var target_y: float = 135.0 + (title_separation * (w * 0.008)) * (i - selected)
		hm.position.y = lerpf(hm.position.y, target_y, scroll_lerp)
	# arrow animations wow i gotta do this shit on update so it looks right damn fuck me.
	arrow_animations()

func _unhandled_input(event: InputEvent) -> void:
	if exiting or event.is_echo():
		return
	var move_axis: int = int(Input.get_axis("ui_up", "ui_down"))
	var diff_axis: int = int(Input.get_axis("ui_left", "ui_right"))
	if move_axis != 0: change_selection(move_axis)
	if diff_axis != 0: change_difficulty(diff_axis)
	if event.is_action("ui_accept"):
		exiting = true
		go_to_gameplay()
	if event.is_action("ui_cancel"):
		exiting = true
		Global.change_scene("uid://c6hgxbdiwb6yn")

func create_titles() -> void:
	var title_rect: TextureRect = $"level_ui/titles/title_temp".duplicate()
	$"level_ui/titles/title_temp".queue_free()
	for i: int in levels.size():
		var lvl: SongPlaylist = levels.list[i]
		if lvl.visible == 1 | 2: continue
		var level_title: TextureRect = title_rect.duplicate()
		if lvl.title_texture: level_title.texture = lvl.title_texture
		level_title.modulate.a = 0.6 if i != selected else 1.0
		title_positions.append(level_title.position)
		titles.add_child(level_title)

func change_selection(next: int = 0) -> void:
	selected = wrapi(selected + next, 0, levels.size())
	if next != 0:
		Global.play_sfx(Global.resources.get_resource("scroll"))
		for i: Control in titles.get_children():
			var target_y: int = i.get_index() - selected
			i.modulate.a = 1.0 if target_y == 0 else 0.6
	change_difficulty()
	change_bg_color()
	update_tracklist()

func change_difficulty(next: int = 0) -> void:
	difficulty = wrapi(difficulty + next, 0, current_level.campaign_difficulties.size())
	if next != 0: Global.play_sfx(Global.resources.get_resource("scroll"))
	difficulty_name = current_level.campaign_difficulties[difficulty]

	difficulty_sprite.texture = difficulty_textures[difficulty]
	difficulty_sprite.visible = is_instance_valid(difficulty_textures[difficulty])
	
	if difficulty_sprite.visible:
		if arrow_tween: arrow_tween.kill()
		if difficulty_tween: difficulty_tween.kill()
		difficulty_sprite.self_modulate.a = 0.0
		difficulty_sprite.position.y -= 10
		difficulty_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).set_parallel(true)
		difficulty_tween.tween_property(difficulty_sprite, "position:y", initial_y_diff, 0.15) # this causes a really funny bug that I'm not fixing.
		difficulty_tween.tween_property(difficulty_sprite, "self_modulate:a", 1.0, 0.15)
		var diff_width: float = difficulty_sprite.texture.get_width()
		arrow_tween = create_tween().set_parallel(true)
		var left_width: float = left_arrow_sprite.texture.get_width()
		arrow_tween.tween_property(left_arrow_sprite, "position:x", (left_width - diff_width) - 130, 0.15)
		var right_width: float = right_arrow_sprite.texture.get_width()
		arrow_tween.tween_property(right_arrow_sprite, "position:x", (right_width + diff_width) - 250, 0.15)
	
	# if i ever make it a texturerect or whatever thanks BlueColorsin
	#small_arrow.x = ((small_arrow.width - big_arrow.width) / 2) + big_arrow.x
	#small_arrow.y = ((small_arrow.height - big_arrow.height) / 2) + big_arrow.y

func go_to_gameplay() -> void:
	var title: TextureRect = titles.get_child(selected)
	Global.begin_color_flicker(title, Color.WHITE, Color(0.2, 1.0, 1.0))
	Global.play_sfx(Global.resources.get_resource("confirm"))
	await get_tree().create_timer(0.8).timeout
	Conductor.stop_music()
	var next_playlist: = get_songs()
	Gameplay.set_game_mode(Gameplay.GameMode.STORY)
	if Gameplay.playlist != next_playlist:
		Gameplay.set_playlist(next_playlist, difficulty_name)
	Gameplay.current_song = 0 # make sure
	Global.change_scene("uid://cvf84mr6iepcs")

func change_bg_color() -> void:
	if yellow.color == current_level.level_color:
		return
	if yellow_tween: yellow_tween.kill()
	yellow_tween = create_tween().set_ease(Tween.EASE_OUT_IN)
	yellow_tween.tween_property(yellow, "color", current_level.level_color, 0.6)

func update_tracklist() -> void:
	tracks.text = "\n\n"
	for i: int in current_level.list.size():
		if current_level.list[i].visible == 2 | 3:
			continue
		tracks.text += current_level.list[i].name
		if i < current_level.list.size():
			tracks.text += "\n"
	tagline.text = current_level.tagline

func arrow_animations() -> void:
	var holding_left: bool = Input.is_action_pressed("ui_left")
	var holding_right: bool = Input.is_action_pressed("ui_right")
	if holding_left or Input.is_action_just_released("ui_left"):
		left_arrow_sprite.frame = int(holding_left)
	if holding_right or Input.is_action_just_released("ui_right"):
		right_arrow_sprite.frame = int(holding_right) + 2

func get_songs() -> Array[String]:
	var folders: Array[String] = []
	for i: SongItem in current_level.list:
		if i.visible == 3: continue
		folders.append(i.folder)
	return folders

func reset_music() -> void:
	var play_default: bool = Conductor.is_music_playing() and Conductor.get_main_stream() != Global.DEFAULT_SONG
	if play_default or not Conductor.is_music_playing():
		if play_default:
			Global.request_audio_fade(Conductor.bound_music, 0.0, 0.5)
			await Global.music_fade_tween.finished
		Conductor.bpm = Global.DEFAULT_SONG.bpm
		Conductor.set_music_stream(Global.DEFAULT_SONG)
		Conductor.play_music(0.0, 0.7)
	Conductor.set_music_volume(0.7) # if it's playing.
