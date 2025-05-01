class_name Gameplay extends Node2D

enum GameMode {
	STORY = 0,
	FREEPLAY = 1,
	CHARTING = 2,
}

## Default HUD scenes to use, mainly for settings and stuff.
var DEFAULT_HUDS: Dictionary[String, PackedScene] = {
	"Classic": load("uid://br6ornbfmuj7l"),
	"Advanced": load("uid://bjkg052ui3mnl"),
	"Psych": load("uid://chxabingjikr6")
}
## Default Pause Menu, used if there's none set in the Chart Assets.
const DEFAULT_PAUSE_MENU: PackedScene = preload("uid://bpmp1nmibtels")
## Default Health Percentage.
const DEFAULT_HEALTH_VALUE: int = 50
## Default Health Weight (how much should it be multiplied by when gaining)
const DEFAULT_HEALTH_WEIGHT: int = 5

var player_strums: NoteField
# I need this to be static because of story mode,
# since it reuses the same tally from the previous song.
static var tally: Tally
static var current: Gameplay
static var chart: Chart

#region Playlist

static var playlist: Array[Chart] = []
static var current_song: int = 0

static func set_playlist(folders: Array[String] = ["test"], difficulty: StringName = Global.DEFAULT_DIFFICULTY) -> void:
	clear_playlist()
	# in case you fuck up.
	if folders.is_empty() or folders == [""] or folders == ["null"]:
		folders = ["test"]
	for song: String in folders:
		Gameplay.playlist.append(Chart.detect_and_parse(song, difficulty))
	change_playlist_song(0, true) # just making sure

static func change_playlist_song(next: int = 0, no_scene_checks: bool = false) -> void:
	Gameplay.current_song = clampi(current_song + next, 0, playlist.size())
	var songs_ended: bool = Gameplay.current_song > Gameplay.playlist.size() - 1
	if not songs_ended:
		Gameplay.chart = playlist[current_song]
	if not no_scene_checks:
		if songs_ended: Gameplay.current.exit_game()
		else: Global.reload_scene(true)

static func clear_playlist() -> void:
	Gameplay.current_song = 0
	Gameplay.playlist.clear()

static func exit_to_menu(gm: int = Gameplay.game_mode) -> void:
	var uid: String = "uid://c5qnedjs8xhcw"
	match gm:
		Gameplay.GameMode.STORY: uid = "uid://dakw6tmvuvou7"
		_: Gameplay.play_inst_outside()
	Global.change_scene(uid)

static var game_mode: GameMode = GameMode.FREEPLAY

static func set_game_mode(mode: Gameplay.GameMode = Gameplay.GameMode.FREEPLAY) -> void:
	game_mode = mode

## Returns a game mode string based on the integer given.[br]
## [code]1 = "Story Mode"[/code][br]
## [code]2 = "Freeplay"[/code][br]
## [code]3 = "Charting"[/code][br]
## Anything else will return [code]"Unknown"[/code]
static func get_mode_string(gm: int) -> String:
	match gm:
		0: return "Story Mode"
		1: return "Freeplay"
		2: return "Charting"
		_: return "Unknown"

#endregion

var local_tally: Tally
var local_settings: Settings
var assets: ChartAssets
var scripts: ScriptPack

@onready var music: AudioStreamPlayer = $%"music_player"
@onready var note_group: Node2D = $"hud_layer/note_group"
@onready var note_fields: Control = $"hud_layer/note_fields"

@onready var hud_layer: CanvasLayer = $"hud_layer"
@onready var default_hud_scale: Vector2 = $"hud_layer".scale

var song_name: String = "Unknown"
var difficulty_name: String = "???"

var hud: TemplateHUD
var camera: Camera2D
var stage_bg: FunkinStage2D
var player: Actor2D
var enemy: Actor2D
var dj: Actor2D

@onready var game_mode_name: String = Gameplay.get_mode_string(game_mode)
var judgements: JudgementList = preload("uid://fj361lysi7nc")
var timed_events: Array[TimedEvent] = []
var should_process_events: bool = true
var event_position: int = 0

var ending: bool = false
var starting: bool = true
var has_enemy_track: bool = false
var hud_is_built_in: bool = true
## This will move the enemy character and hide the dj character[br]
## Only really used for tutorial.
var tutorial_dj: bool = true

var health: int = Gameplay.DEFAULT_HEALTH_VALUE:
	set(new_health): health = clampi(new_health, 0, 100)

static func play_inst_outside() -> void:
	if Gameplay.chart and Gameplay.chart.assets:
		Global.play_bgm(Gameplay.chart.assets.instrumental, 0.01)
		var length: float = Gameplay.chart.assets.instrumental.get_length()
		Global.bgm.seek(randf_range(0, length * 0.5))
		Global.request_audio_fade(Global.bgm, 0.7, 1.0)

func _ready() -> void:
	current = self
	get_tree().paused = false
	local_settings = Global.settings.duplicate()
	local_tally = Tally.new()
	scripts = ScriptPack.new()
	Tally.use_epics = local_settings.use_epics
	if not tally:
		tally = Tally.new()
	else:
		# merge tallies if it's not a local one
		tally.merge(local_tally)
	scripts.load_global_scripts()
	if chart:
		assets = chart.assets
		scripts.load_song_scripts(chart.parsed_values.song_name, chart.parsed_values.difficulty)
		timed_events = chart.scheduled_events.duplicate()
		difficulty_name = chart.parsed_values.difficulty
		song_name = chart.name
	add_child(scripts)
	scripts.call_func("_pack_entered")
	if chart.assets:
		load_stage(chart.stage if chart and chart.stage else null)
		load_characters()
		load_streams()
		reload_hud()
	
	init_note_spawner()
	setup_note_fields()
	
	Conductor.on_beat_hit.connect(on_beat_hit)
	scripts.call_func("_ready_post")
	var tick_scripts: Callable = func(tick: int) -> void:
		scripts.call_func("countdown_tick", [tick])
	if hud: hud.on_countdown_tick.connect(tick_scripts)
	camera = get_viewport().get_camera_2d()
	restart_song()

func setup_note_fields() -> void:
	# TODO: rewrite how note fields work entirely.
	for i: NoteField in note_fields.get_children():
		if i.player: i.player.setup()
	player_strums = note_fields.get_child(0)

func kill_every_note(advancing: bool = false) -> void:
	for note: Note in note_group.get_children():
		if advancing:
			var cur_time: float = note.time
			for i: NoteData in note_group.note_list:
				if cur_time < Conductor.time and i.time > Conductor.time:
					var index: int = note_group.note_list.find(i)
					note_group.list_position = index
					print_debug(index)
					break
		note.queue_free()

func restart_song() -> void:
	Chart.reset_timing_changes(chart.timing_changes)
	Conductor.reset(chart.get_bpm(), false)
	starting = true
	ending = false
	if music:
		music.stream_paused = true
		music.seek(0.0)
	# disable note spawning and event dispatching.
	should_process_events = false
	note_group.active = false
	local_tally.zero()
	health = Gameplay.DEFAULT_HEALTH_VALUE
	tally.merge(local_tally)
	# unfire any previously fired events
	for event: TimedEvent in timed_events:
		event.was_fired = false
	event_position = 0
	should_process_events = not timed_events.is_empty()
	# kill notes in the note group to not give you damage
	kill_every_note()
	note_group.offset = local_settings.note_offset
	note_group.list_position = 0
	note_group.active = true
	# set initial scroll speed.
	if chart: fire_timed_event(chart.get_velocity_change(0.0))
	for note_field: NoteField in note_fields.get_children():
		if note_field.player is Player:
			note_field.player.keys_held.fill(false)
			note_field.player.note_group = note_group
		for i: int in note_field.get_child_count():
			note_field.play_animation(i)
	_sync_rpc_timestamp()
	play_countdown()

func play_countdown(offset: float = 0.0) -> void:
	var skip_countdown: bool = false
	var crotchet_offset: float = -3.0
	if hud:
		skip_countdown = hud.skip_countdown
		if not skip_countdown:
			crotchet_offset = -5.0
			hud.start_countdown()
	crotchet_offset += offset
	Conductor.set_time(Conductor.crotchet * crotchet_offset)
	_default_rpc()

func _exit_tree() -> void:
	current = null
	Conductor.length = -1.0
	Conductor.on_beat_hit.disconnect(on_beat_hit)
	local_settings.unreference()

func _process(delta: float) -> void:
	if music and music.playing and not ending:
		Conductor.update(music.get_playback_position() + AudioServer.get_time_since_last_mix())
	elif not Conductor.active:
		Conductor.active = true
	if should_process_events:
		process_timed_events()
	if starting:
		if Conductor.time >= 0.0:
			if music: music.play(Conductor.time)
			starting = false
	else:
		if Conductor.time >= Conductor.length and not ending:
			end_song()
		
	# hud bumping #
	if hud and hud_layer.is_inside_tree() and hud_layer.scale != Vector2.ONE:
		hud_layer.scale = hud.get_bump_lerp_vector(hud_layer.scale, default_hud_scale, delta)
		hud_layer.offset.x = (hud_layer.scale.x - 1.0) * -(get_viewport_rect().size.x * 0.5)
		hud_layer.offset.y = (hud_layer.scale.y - 1.0) * -(get_viewport_rect().size.y * 0.5)

func _unhandled_key_input(_event: InputEvent) -> void:
	if OS.is_debug_build() and not starting and _event.pressed and not _event.is_echo():
		match _event.keycode:
			KEY_F4:
				skip_to_time(music.get_playback_position() + 10)
			KEY_END:
				music.stop()
				note_group.active = false
				should_process_events = false
				tally.merge(local_tally) # just in case
				tally.is_valid = false
				Conductor.time = Conductor.length
	
	if Input.is_action_just_pressed("ui_pause"):
		var pause_menu: PackedScene
		if assets and assets.pause_menu:
			pause_menu = assets.pause_menu
		else:
			pause_menu = DEFAULT_PAUSE_MENU
		if music: music.stop()
		var instance: Control = pause_menu.instantiate()
		instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		instance.tree_exited.connect(_default_rpc)
		hud_layer.add_child(instance)
		get_tree().paused = true
		return
	if player_strums and player_strums.player is Player and player:
		player.lock_on_sing = player_strums.player.keys_held.has(true)

func skip_to_time(time: float = 0.0) -> void:
	note_group.active = false
	music.seek(time)
	Conductor.time = time
	if Conductor.time >= Conductor.length:
		music.stop()
		tally.merge(local_tally) # just in case
		tally.is_valid = false
	kill_every_note(true)
	note_group.active = true

func process_timed_events() -> void:
	#var idx: int = timed_events.find(current_event) # if i need it...
	while event_position < timed_events.size():
		var current_event: TimedEvent = timed_events[event_position]
		if Conductor.time < current_event.time:
			return
		if not current_event.was_fired:
			fire_timed_event(current_event)
		event_position += 1
		if event_position >= timed_events.size():
			should_process_events = false

func fire_timed_event(event: TimedEvent) -> void:
	if not event:
		return
	if event.efire:
		event.efire.call()
	else: # TODO: call a script here?
		pass
	event.was_fired = true

func load_stage(stage_path: PackedScene = null) -> void:
	if has_node("stage"): remove_child(get_node("stage"))
	if not stage_path:
		stage_bg = FunkinStage2D.new()
		var dummy_stage: ColorRect = ColorRect.new()
		dummy_stage.size = get_viewport_rect().size * 5.0
		dummy_stage.position = -dummy_stage.size * 0.5
		dummy_stage.color = Color.DIM_GRAY
		stage_bg.add_child(dummy_stage)
		var dummy_camera: Camera2D = Camera2D.new()
		dummy_camera.global_position = get_viewport_rect().size * 0.5
		dummy_camera.position_smoothing_enabled = true
		dummy_camera.rotation_smoothing_enabled = true
		stage_bg.add_child(dummy_camera)
		add_child(stage_bg)
		move_child(stage_bg, 1)
		return
	stage_bg = stage_path.instantiate()
	print_debug("changed stage to ", stage_bg.scene_file_path)
	add_child(stage_bg)
	move_child(stage_bg, 1)

func get_actor_from_index(idx: int) -> Actor2D:
		var actor: Actor2D
		match idx:
			0: actor = player
			1: actor = enemy
			2: actor = dj
		return actor

func load_characters() -> void:
	if not chart or (chart and not chart.characters):
		print_debug("unable to load characters.")
		return
	const MARKER_NAMES: PackedStringArray = ["player", "enemy", "dj"]
	const DEFAULT_POS: PackedVector2Array = [ Vector2(1000, 450), Vector2(315, 450), Vector2(620, 420) ]
	for idx: int in chart.characters.size():
		var i: PackedScene = chart.characters[idx]
		if not i or not i.can_instantiate(): continue
		var new_actor: Actor2D = i.instantiate()
		new_actor.position = DEFAULT_POS[idx]
		set(MARKER_NAMES[idx], new_actor)
		#print_debug("loaded ", new_actor.name, " as ", MARKER_NAMES[idx])
		if new_actor == player: new_actor.faces_left = true
		if not stage_bg: # most here as a safety measure, to add the characters regardless of whether there's a stage or not.
			add_child(new_actor)
			if new_actor == dj: move_child(dj, player.get_index())
	# load the characters inside the stage if possible (layering purposes)
	for idx: int in MARKER_NAMES.size():
		var ii: String = MARKER_NAMES[idx]
		var new_actor: Actor2D = get_actor_from_index(idx)
		if new_actor:
			if stage_bg.has_node(ii):
				var new_position: Marker2D = stage_bg.get_node(ii)
				var actor_idx: int = new_position.get_index()
				new_actor.self_modulate = new_position.self_modulate
				new_actor.position = new_position.position
				new_actor.modulate = new_position.modulate
				new_actor.z_index = new_position.z_index
				stage_bg.remove_child(new_position)
				stage_bg.add_child(new_actor)
				stage_bg.move_child(new_actor, actor_idx)
			else:
				stage_bg.add_child(new_actor)
				if new_actor == dj: stage_bg.move_child(dj, player.get_index())

func reload_hud(custom_hud: PackedScene = null) -> void:
	var idx: int = 0
	var huds: Array = []
	if hud: huds.append(hud)
	if hud_layer.has_node("hud"):
		idx = hud_layer.get_node("hud").get_index()
		huds.append(hud_layer.get_node("hud"))
	for hud_node: Control in huds:
		hud_node.set_process(false) # just in case
		hud_node.queue_free()
	var hud_type: String = local_settings.hud_style
	var fallback: bool = false
	if hud_type.to_snake_case() == "default":
		var next_hud: PackedScene = custom_hud if custom_hud else chart.assets.hud
		if next_hud:
			hud = next_hud.instantiate()
		else:
			fallback = true
			hud_is_built_in = true
	else:
		if fallback: hud_type = "Classic"
		if hud_type in DEFAULT_HUDS:
			hud = DEFAULT_HUDS[hud_type].instantiate()
			hud_is_built_in = true
	hud_layer.add_child(hud)
	hud_layer.move_child(hud, idx)
	# update hud if possible
	if hud:
		hud.init_vars()
		hud.update_score_text(true) # pretend its a miss
		hud.update_health(health)

func load_streams() -> void:
	if chart.assets and chart.assets.instrumental:
		music.stream.set_sync_stream(0, chart.assets.instrumental)
		Conductor.length = chart.assets.instrumental.get_length()
		if chart.assets.vocals:
			has_enemy_track = chart.assets.vocals.size() > 1
			for i: int in chart.assets.vocals.size():
				music.stream.set_sync_stream(i + 1, chart.assets.vocals[i])

func init_note_spawner() -> void:
	note_group.on_note_spawned.connect(func(data: NoteData, note: Node2D) -> void:
		var receptor: = note_fields.get_child(data.side).get_child(data.column)
		note.global_position = receptor.global_position
		note.scale = note_fields.get_child(data.side).scale
		note.note_field = note_fields.get_child(data.side)
	)
	if chart and not chart.notes.is_empty():
		note_group.note_list = chart.notes.duplicate(true)
		if Conductor.length <= 0.0: Conductor.length = chart.notes.back().time

func on_note_hit(note: Note) -> void:
	if note.was_hit or note.column == -1:
		return
	note.was_hit = true
	var abs_diff: float = absf(note.time - Conductor.playhead) * 1000.0
	var judged_tier: int = Tally.judge_time(abs_diff)
	note.judgement = judgements.list[judged_tier]
	if player and note.side == 0 and player.able_to_sing:
		player.sing(note.column, note.arrow.visible)
		if music: music.stream.set_sync_stream_volume(1, linear_to_db(1.0))
	if note.can_splash(): note.display_splash()
	# kill everyone, and everything in your path
	health += (DEFAULT_HEALTH_WEIGHT * judged_tier)
	#print_debug("Health increased by ", DEFAULT_HEALTH_WEIGHT * judged_tier, "%")
	# Scoring Stuff
	local_tally.increase_score(abs_diff)
	local_tally.increase_combo(1)
	if note.judgement.combo_break and local_tally.combo > 0:
		local_tally.breaks += 1
		local_tally.combo = 0
	local_tally.update_tier_score(judged_tier)
	# Update HUD
	tally.merge(local_tally)
	if hud:
		hud.display_judgement(note.judgement)
		hud.display_combo(local_tally.combo)
		hud.update_score_text(false)
		hud.update_health(health)
	kill_yourself()

func kill_yourself() -> void: # thanks Unholy
	if health <= 0: # игра окоичена!
		hud_layer.hide()
		if music: music.stop()
		print_debug("Died with a MA of ", tally.calculate_epic_ratio(), " and a PA of ", tally.calculate_sick_ratio())
		local_tally.zero()
		tally.merge(local_tally)
		if hud:
			hud.update_health(health)
			hud.update_score_text(true)
		player.die()

func try_revive() -> void:
	if health > 0:
		player.show()
		hud_layer.show()

func on_note_miss(note: Note, idx: int = -1) -> void:
	var damage_boost: float = -note.hold_size if note and note.hold_size > 0.0 else -2.0
	if damage_boost < -10.0: damage_boost = -10.0
	if note and note.was_missed or idx == -1: return
	if local_tally.combo > 0: # break combo (if needed)
		local_tally.combo = 0
	#else: # decrease for miss combo
	#	local_tally.combo -= 1
	local_tally.score += Tally.MISS_SCORE
	local_tally.increase_misses(1) # increase by one
	player.sing(idx, true, "miss")
	health += int(-5 + damage_boost)
	if music: music.stream.set_sync_stream_volume(1, linear_to_db(0.0))
	if assets and assets.miss_note_sounds:
		Global.play_sfx(assets.miss_note_sounds.pick_random(), randf_range(0.1, 0.4))
	#print_debug("Health damaged by ", int(Tally.MISS_POINTS + damage_boost), "%")
	tally.merge(local_tally)
	if hud:
		hud.update_score_text(true)
		hud.update_health(health)
	kill_yourself()

func on_beat_hit(beat: float) -> void:
	if hud and int(beat) > 0 and int(beat) % 4 == 0:
		hud_layer.scale += Vector2(hud.get_bump_scale(), hud.get_bump_scale())

func end_song() -> void:
	ending = true
	await get_tree().create_timer(0.5).timeout
	change_playlist_song(1)

func exit_game() -> void:
	if tally:
		# TODO: save level score.
		var is_story: bool = Gameplay.game_mode == Gameplay.GameMode.STORY
		tally.save_record(chart.parsed_values.song_name, chart.parsed_values.difficulty, is_story)
		tally = null
	Gameplay.exit_to_menu()

func _default_rpc() -> void:
	Global.update_discord(game_mode_name, "Playing %s (%s)" % [ song_name, difficulty_name.to_upper() ])
	_sync_rpc_timestamp()

func _sync_rpc_timestamp() -> void:
	Global.update_discord_timestamps(int(Conductor.time), int(Conductor.length))
