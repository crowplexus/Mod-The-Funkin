class_name Gameplay extends Node2D

enum GameMode {
	STORY = 0,
	FREEPLAY = 1,
	CHARTING = 2,
}

signal on_note_spawned(data: NoteData, note: Note)

## Notetypes that can be spawned.
const NOTE_TYPES: Dictionary[String, PackedScene] = {
	"mine": preload("uid://b4e0quuk03nqs"),
	"_": preload("uid://gib0vewis1qh"),
}

## Default HUD scenes to use, mainly for settings and stuff.
var DEFAULT_HUDS: Dictionary[String, PackedScene] = {
	"Classic": load("uid://br6ornbfmuj7l"),
	"Advanced": load("uid://bjkg052ui3mnl"),
	"Psych": load("uid://chxabingjikr6"),
}
## Default Pause Menu, used if there's none set in the Chart Assets.
const DEFAULT_PAUSE_MENU: PackedScene = preload("uid://bpmp1nmibtels")
const DEFAULT_HEALTH_VALUE: int = 50 ## Default Health Percentage.
const MISS_HEALTH_BONUS: int = -8 ## Default Health Bonus for Missing.

var player_id: int = 0
var player_sl: Strumline
var player_botplay: bool = false
# I need this to be static because of story mode,
# since it reuses the same tally from the previous song.
static var tally: Tally
static var current: Gameplay
static var chart: Chart

#region Static Stuff

static var playlist: Array[Chart] = []
static var current_song: int = 0

static func set_playlist(folders: Array[String] = ["test"], difficulty: StringName = Global.DEFAULT_DIFFICULTY) -> void:
	chart = null
	clear_playlist()
	# in case you fuck up.
	if folders.is_empty() or folders == [""] or folders == ["null"]:
		folders = ["test"]
	for song: String in folders:
		Gameplay.playlist.append(Chart.detect_and_parse(song, difficulty))
	change_playlist_song(0, true) # just making sure

static func change_playlist_song(next: int = 0, no_scene_checks: bool = false) -> void:
	Gameplay.current_song = current_song + next
	var songs_ended: bool = Gameplay.current_song > Gameplay.playlist.size() - 1
	if not songs_ended:
		Gameplay.chart = playlist[current_song]
		Chart.reset_timing_changes(Gameplay.chart.timing_changes)
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

static func play_inst_outside() -> void:
	Conductor.clear_music_streams()
	var random_position: float = randf_range(0, Conductor.length * 0.5)
	Conductor.set_music_stream(Gameplay.chart.assets.instrumental)
	Conductor.play_music(random_position, 0.01, true)
	Global.request_audio_fade(Conductor.bound_music, 0.7, 1.0)
	Conductor.bpm = Gameplay.chart.get_bpm(Gameplay.chart.time_bpm_change(random_position))

#endregion

var local_tally: Tally
var local_settings: Settings
var assets: ChartAssets
var scripts: ScriptPack

@onready var strumlines: Control = $"hud_layer/strumlines"
@onready var default_strumline_position: Vector2 = strumlines.position

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

var note_spawn_index: int = 0
var notes_to_spawn: Array[NoteData] = []
var timed_events: Array[TimedEvent] = []
var should_process_events: bool = true
var should_spawn_notes: bool = true
var event_position: int = 0

var ending: bool = false
var starting: bool = true
var no_fail_mode: bool = false
var has_enemy_track: bool = false
var hud_is_built_in: bool = true
## This will move the enemy character and hide the dj character[br]
## Only really used for tutorial.
var tutorial_dj: bool = true

var health: int = Gameplay.DEFAULT_HEALTH_VALUE:
	set(new_health): health = clampi(new_health, 0, 100)
var display_health: int = Gameplay.DEFAULT_HEALTH_VALUE:
	get: return health if player_id == 0 else (100 - health)

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
		notes_to_spawn = chart.notes.duplicate()
		song_name = chart.name
	add_child(scripts)
	scripts.call_func("_pack_entered")
	if chart and chart.assets:
		load_stage(chart.stage if chart and chart.stage else null)
		load_characters()
		load_streams()
		reload_hud()
	
	if chart and Conductor.length <= 0.0:
		Conductor.length = chart.notes.back().time
	player_sl = strumlines.get_child(player_id)
	for strums: Strumline in strumlines.get_children():
		if not strums.skin and assets and assets.noteskin:
			strums.skin = assets.noteskin
		if strums.skin: strums.reload_skin()
		strums.input.setup()
	player_sl.input.botplay = player_botplay
	if player_botplay: tally.is_valid = false
	
	# apply this to other strumlines later if its quants.
	if not player_botplay and Global.settings.note_color_mode > 0:
		for strum: StrumNote in player_sl.strums:
			strum.allow_color_overriding = true
	
	Conductor.on_beat_hit.connect(on_beat_hit)
	scripts.call_func("_ready_post")
	var tick_scripts: Callable = func(tick: int) -> void:
		scripts.call_func("countdown_tick", [tick])
	if hud and hud.is_inside_tree():
		hud.on_countdown_tick.connect(tick_scripts)
	camera = get_viewport().get_camera_2d()
	restart_song()

func kill_every_note(advancing: bool = false) -> void:
	for strums: Strumline in strumlines.get_children():
		for note: Note in strums.notes.get_children():
			if advancing:
				var cur_time: float = note.time
				for i: NoteData in notes_to_spawn:
					if cur_time < Conductor.time and i.time > Conductor.time:
						note_spawn_index = notes_to_spawn.find(i)
						break
			note.queue_free()

func restart_song() -> void:
	starting = true
	ending = false
	Conductor.toggle_pause_music(false)
	if chart: Conductor.reset(chart.get_bpm(), true)
	# disable note spawning and event dispatching.
	should_process_events = false
	should_spawn_notes = false
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
	note_spawn_index = 0
	should_spawn_notes = not notes_to_spawn.is_empty()
	# set initial scroll speed.
	if chart: fire_timed_event(chart.get_velocity_change(0.0))
	for strums: Strumline in strumlines.get_children():
		for i: int in strums.get_child_count():
			strums.play_strum(StrumNote.States.STATIC, i)
	_sync_rpc_timestamp()
	play_countdown()

func play_countdown(offset: float = 0.0) -> void:
	var skip_countdown: bool = false
	var crotchet_offset: float = -3.0
	if hud and hud.is_inside_tree():
		skip_countdown = hud.skip_countdown
		if not skip_countdown:
			crotchet_offset = -5.0
			hud.start_countdown()
	crotchet_offset += offset
	Conductor.set_time(Conductor.crotchet * crotchet_offset)
	_default_rpc()

func _exit_tree() -> void:
	current = null
	Conductor.on_beat_hit.disconnect(on_beat_hit)
	local_settings.unreference()

func _process(delta: float) -> void:
	if starting:
		if Conductor.time >= 0.0:
			Conductor.toggle_pause_music(false) # just in case.
			Conductor.play_music(0.0, 1.0, false)
			starting = false
	else:
		if Conductor.time >= Conductor.length and not ending:
			ending = true
			end_song()
	if not no_fail_mode and health <= 0:
		kill_yourself(get_actor_from_index(player_id))
	# hud bumping #
	if hud_layer.is_inside_tree() and hud_layer.scale != Vector2.ONE:
		hud_layer.scale = hud.get_bump_lerp_vector(hud_layer.scale, default_hud_scale, delta)
		hud_layer.offset.x = (hud_layer.scale.x - 1.0) * -(get_viewport_rect().size.x * 0.5)
		hud_layer.offset.y = (hud_layer.scale.y - 1.0) * -(get_viewport_rect().size.y * 0.5)

func _physics_process(_delta: float) -> void:
	# I don't need this to run every single frame.
	if should_process_events: process_timed_events()
	if should_spawn_notes: do_note_spawning()

func _unhandled_key_input(_event: InputEvent) -> void:
	if OS.is_debug_build() and not starting and _event.pressed and not _event.is_echo():
		match _event.keycode:
			KEY_F4:
				skip_to_time(Conductor.time + 10)
			KEY_END:
				Conductor.stop_music()
				should_spawn_notes = false
				should_process_events = false
				tally.merge(local_tally) # just in case
				tally.is_valid = false
				Conductor.time = Conductor.length
	
	if Input.is_action_just_pressed("ui_pause"):
		Conductor.toggle_pause_music(false) # FUCK?
		var pause_menu: PackedScene
		if assets and assets.pause_menu:
			pause_menu = assets.pause_menu
		else:
			pause_menu = DEFAULT_PAUSE_MENU
		var instance: Control = pause_menu.instantiate()
		instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		instance.tree_exited.connect(_default_rpc)
		hud_layer.add_child(instance)
		get_tree().paused = true
		return
	if player_sl and player:
		player.lock_on_sing = player_sl.input.keys_held.has(true)

func skip_to_time(time: float = 0.0) -> void:
	should_spawn_notes = false
	Conductor.seek_music(time)
	Conductor.time = time
	if Conductor.time >= Conductor.length:
		Conductor.stop_music()
		tally.merge(local_tally) # just in case
		tally.is_valid = false
	kill_every_note(true)
	should_spawn_notes = true

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
				new_actor.scale = new_position.scale
				stage_bg.remove_child(new_position)
				stage_bg.add_child(new_actor)
				stage_bg.move_child(new_actor, actor_idx)
			else:
				stage_bg.add_child(new_actor)
				if new_actor == dj: stage_bg.move_child(dj, player.get_index())

## Same as HUDs managing this except its not dependent on HUDs.[br]Made for convenience.
func get_strumline_position(settings: Settings) -> Vector2:
	var pos: Vector2 = default_strumline_position
	match settings.scroll:
		0: pos.y = 0
		1: pos.y = 500
	return pos

func reload_hud(custom_hud: PackedScene = null) -> void:
	# huds are completely able to change this so make sure its set to default if it happens.
	strumlines.position = get_strumline_position(Global.settings)
	var idx: int = 0
	var huds: Array = []
	if hud: huds.append(hud)
	if hud_layer.has_node("hud"):
		idx = hud_layer.get_node("hud").get_index()
		huds.append(hud_layer.get_node("hud"))
	elif hud:
		idx = hud.get_index()
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
	if fallback: hud_type = "Classic"
	if hud_type in DEFAULT_HUDS:
		hud = DEFAULT_HUDS[hud_type].instantiate()
		hud_is_built_in = true
	# update hud if possible
	if hud:
		hud_layer.add_child(hud)
		hud_layer.move_child(hud, idx)
		if hud.is_inside_tree():
			hud.init_vars()
			hud.update_health(display_health)
			hud.update_score_text(true) # pretend its a miss
			hud.settings_changed(Global.settings)

func load_streams() -> void:
	Conductor.load_chart_music(chart)
	if chart.assets and chart.assets.instrumental:
		has_enemy_track = chart.assets.vocals.size() > 1

func do_note_spawning() -> void:
	while note_spawn_index < notes_to_spawn.size():
		var note_data: NoteData = notes_to_spawn[note_spawn_index]
		var strumline: Strumline = strumlines.get_child(note_data.side)
		var spawn_time: float = 0.9
		if strumline.speed < 1.0: spawn_time /= strumline.speed
		if not strumline or absf(note_data.time - Conductor.playhead) > spawn_time:
			break
		var new_note: Note = get_unspawned_note(strumline, note_data)
		strumline.notes.add_child(new_note)
		new_note.reload(note_data)
		on_note_spawned.emit(note_data, new_note)
		note_spawn_index = notes_to_spawn.find(note_data) + 1

func get_unspawned_note(strumline: Strumline, note_data: NoteData) -> Node:
	#for node: Node in strumline.notes.sget_children():
	#	if not node.visible:
	#		return node
	var types: Dictionary[String, PackedScene] = NOTE_TYPES
	if strumline.skin and note_data.kind in strumline.skin.note_scenes:
		types = strumline.skin.note_scenes
	var unspawned_note: = types[note_data.kind].instantiate()
	unspawned_note.name = "note_%s_%s" % [ unspawned_note.name, note_spawn_index ]
	unspawned_note.strumline = strumline
	unspawned_note.data = note_data
	return unspawned_note

func on_note_hit(note: Note) -> void:
	if note.was_hit or note.column == -1:
		return
	note.was_hit = true
	var abs_diff: float = absf(note.time - Conductor.playhead) * 1000.0
	var judged_tier: int = Tally.judge_time(abs_diff)
	var judgement: Judgement = judgements.list[judged_tier]
	note.splash_type = judgement.splash_type
	note.judgement = judgement.name
	
	var character: Actor2D = get_actor_from_index(note.side)
	if character and character.able_to_sing:
		character.sing(note.column, note.arrow.visible)
		Conductor.set_music_volume(1.0, 1)
	if hud and hud.disable_note_splashes:
		note.splash_type = Judgement.SplashType.DISABLED
	if note.can_splash(): note.display_splash()
	# kill everyone, and everything in your path
	health += judgement.health_bonus
	#print_debug("Health increased by ", DEFAULT_HEALTH_WEIGHT * judged_tier, "%")
	# Scoring Stuff
	local_tally.increase_score(abs_diff)
	local_tally.increase_combo(1)
	if judgement.combo_break and local_tally.combo > 0:
		local_tally.breaks += 1
		local_tally.combo = 0
	local_tally.update_tier_score(judged_tier)
	# Update HUD
	tally.merge(local_tally)
	if hud and hud.is_inside_tree():
		hud.display_judgement(judgement)
		hud.display_combo(local_tally.combo)
		hud.update_score_text(false)
		hud.update_health(display_health)
	if note.strumline == player_sl:
		note._strum.color = judgement.color

func kill_yourself(actor: Actor2D) -> void: # thanks Unholy
	if health <= 0: # игра окоичена!
		hud_layer.hide()
		Conductor.stop_music()
		print_debug("Died with a MA of ", tally.calculate_epic_ratio(), " and a PA of ", tally.calculate_sick_ratio())
		local_tally.zero()
		tally.merge(local_tally)
		if hud and hud.is_inside_tree():
			hud.update_health(display_health)
			hud.update_score_text(true)
		actor.die()

func try_revive() -> void:
	if health > 0:
		player.show()
		hud_layer.show()
		if hud and hud.is_inside_tree():
			hud.update_health(display_health)
			hud.update_score_text(true)

func on_note_miss(note: Note, idx: int = -1) -> void:
	var damage_boost: float = -note.hold_size if note and note.hold_size > 0.0 else -2.0
	if damage_boost < -10.0: damage_boost = -10.0
	if (note and note.was_missed) or idx == -1: return
	# change scoring
	if local_tally.combo > 0: # break combo (if needed)
		local_tally.combo = 0
	#else: # decrease for miss combo
	#	local_tally.combo -= 1
	local_tally.score += Tally.MISS_SCORE
	local_tally.increase_misses(1) # increase by one
	health += int(MISS_HEALTH_BONUS + damage_boost)
	#print_debug("Health damaged by ", int(Tally.MISS_POINTS + damage_boost), "%")
	tally.merge(local_tally)
	# mute vocals
	Conductor.set_music_volume(0.0, 1)
	if assets and assets.miss_note_sounds:
		Global.play_sfx(assets.miss_note_sounds.pick_random(), randf_range(0.1, 0.4))
	# update hud
	if hud and hud.is_inside_tree():
		hud.update_score_text(true)
		hud.update_health(display_health)
	# play miss animations.
	if player: player.sing(idx, true, "miss")

func on_beat_hit(beat: float) -> void:
	if hud and hud.is_inside_tree() and int(beat) > 0 and int(beat) % 4 == 0:
		hud_layer.scale += Vector2(hud.get_bump_scale(), hud.get_bump_scale())

func end_song() -> void:
	ending = true
	await get_tree().create_timer(0.5).timeout
	change_playlist_song(1)

func exit_game() -> void:
	if tally and chart:
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
