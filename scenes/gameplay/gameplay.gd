class_name Gameplay
extends Node2D

enum PlayMode {
	STORY = (1 << 1),
	FREEPLAY = (2 << 1),
	CHARTING = (3 << 1),
}

## Default HUD scenes to use, mainly for settings and stuff.
var DEFAULT_HUDS: Dictionary[String, PackedScene] = {
	"classic": load("res://scenes/gameplay/hud/classic_hud.tscn"),
	"advanced": load("res://scenes/gameplay/hud/fortnite_hud.tscn"),
}
## Default Pause Menu, used if there's none set in the Chart Assets.
const DEFAULT_PAUSE_MENU: PackedScene = preload("res://scenes/gameplay/adjacent/pause_menu.tscn")
## Default Results Screen.
const DEFAULT_RESULTS_SCREEN: PackedScene = preload("res://scenes/gameplay/adjacent/results_screen.tscn")
## Default Health Percentage.
const DEFAULT_HEALTH_VALUE: int = 50
## Default Health Weight (how much should it be multiplied by when gaining)
const DEFAULT_HEALTH_WEIGHT: int = 5

var player_strums: NoteField
# I need this to be static because of story mode,
# since it reuses the same tally from the previous song.
static var tally: Tally
static var chart: Chart
static var current: Gameplay

var local_tally: Tally
var local_settings: Settings
var assets: ChartAssets
var scripts: ScriptPack

@onready var music: AudioStreamPlayer = $%"music_player"
@onready var note_group: Node2D = $"hud_layer/note_group"
@onready var note_fields: Control = $"hud_layer/note_fields"

@onready var hud_layer: CanvasLayer = $"hud_layer"
@onready var default_hud_scale: Vector2 = $"hud_layer".scale

var hud: TemplateHUD
var camera: Camera2D
var stage_bg: FunkinStage2D
var player: Actor2D
var enemy: Actor2D
var dj: Actor2D

var game_mode: PlayMode = PlayMode.FREEPLAY
var judgements: JudgementList = preload("res://assets/default/judgements.tres")
var timed_events: Array[TimedEvent] = []
var event_position: int = 0
var should_process_events: bool = true

var ending: bool = false
var starting: bool = true
var has_enemy_track: bool = false

var health: int = Gameplay.DEFAULT_HEALTH_VALUE:
	set(new_health): health = clampi(new_health, 0, 100)

func _default_rpc() -> void:
	Global.update_discord("%s" % Global.get_mode_string(game_mode), "In-game")
	Global.update_discord_timestamps(int(Conductor.time), int(Conductor.length))

func _ready() -> void:
	current = self
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
		scripts.load_song_scripts(chart.parsed_values.folder, chart.parsed_values.file)
		timed_events = chart.scheduled_events.duplicate()
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
	if hud: hud.init_vars()
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

func kill_every_note() -> void:
	if note_group:
		for note: Node in note_group.get_children():
			note.queue_free()

func restart_song() -> void:
	if music: music.seek(0.0)
	ending = false
	starting = true
	should_process_events = false
	for event: TimedEvent in timed_events:
		event.was_fired = false
	event_position = 0
	should_process_events = not timed_events.is_empty()
	health = Gameplay.DEFAULT_HEALTH_VALUE
	if note_group: note_group.list_position = 0
	Conductor.reset(chart.get_bpm(), false)
	Conductor.play_offset = local_settings.sync_offset
	local_tally.zero()
	tally.merge(local_tally)
	kill_every_note()
	if chart: fire_timed_event(chart.get_velocity_change(0.0))
	for note_field: NoteField in note_fields.get_children():
		if note_field.player is Player:
			note_field.player.keys_held.fill(false)
			note_field.player.note_group = note_group
		for i: int in note_field.get_child_count():
			note_field.play_animation(i)
		
	if hud:
		hud.update_health(health)
		hud.update_score_text()
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
	if music and music.playing:
		Conductor.update(music.get_playback_position() + AudioServer.get_time_since_last_mix())
	elif not Conductor.active:
		Conductor.active = true
	if should_process_events:
		process_timed_events()
	if starting:
		if Conductor.time >= 0.0:
			_default_rpc()
			if music: music.play(Conductor.time)
			starting = false
	else:
		if not ending and Conductor.time >= Conductor.length:
			ending = true
			await get_tree().create_timer(0.5).timeout
			exit_game()
	# hud bumping #
	if hud_layer.is_inside_tree() and hud_layer.scale != Vector2.ONE:
		hud_layer.scale = hud.get_bump_lerp_vector(hud_layer.scale, default_hud_scale, delta)
		hud_layer.offset.x = (hud_layer.scale.x - 1.0) * -(get_viewport_rect().size.x * 0.5)
		hud_layer.offset.y = (hud_layer.scale.y - 1.0) * -(get_viewport_rect().size.y * 0.5)

func _unhandled_key_input(_event: InputEvent) -> void:
	if _event.pressed and _event.keycode == KEY_END and not starting and OS.is_debug_build():
		music.stop()
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
		if instance.has_signal("on_close"):
			instance.connect("on_close", _default_rpc)
		hud_layer.add_child(instance)
		get_tree().paused = true
		return
	if player_strums and player_strums.player is Player and player:
		player.pause_sing = player_strums.player.keys_held.has(true)

func process_timed_events() -> void:
	#var idx: int = timed_events.find(current_event) # if i need it...
	while event_position < timed_events.size():
		var current_event: TimedEvent = timed_events[event_position]
		if Conductor.time < current_event.time:
			return
		if not current_event.was_fired:
			if current_event.efire: current_event.efire.call()
			else: fire_timed_event(current_event) # hardcoded events
		event_position += 1
		if event_position >= timed_events.size():
			should_process_events = false

func fire_timed_event(event: TimedEvent) -> void:
	if not event:
		return
	match event.name:
		&"Change Camera Focus":
			if camera:
				var offset: Vector2 = Vector2(float(event.values.x) if "x" in event.values else 0.0,
					float(event.values.y) if "y" in event.values else 0.0)
				if event.values.char == -1:
					camera.global_position = offset
				else:
					var actor: Actor2D = get_actor_from_index(event.values.char)
					if actor:
						camera.global_position = actor.global_position + offset
						camera.global_position.x *= 0.85
		&"Change Scroll Speed":
			for note_field: NoteField in note_fields.get_children():
				note_field.speed_change_tween = create_tween()
				note_field.speed_change_tween.tween_property(note_field, "speed", event.values.speed, 1.0)
				note_group.speed = event.values.speed
			#print_debug("scroll speed changed to ", event.values.speed, " at ", Conductor.time)
	event.was_fired = true

func load_stage(stage_path: PackedScene = null) -> void:
	if has_node("stage"): remove_child(get_node("stage"))
	if not stage_path:
		stage_bg = FunkinStage2D.new()
		var dummy_stage: ColorRect = ColorRect.new()
		dummy_stage.size = get_viewport_rect().size * 5.0
		dummy_stage.position = -dummy_stage.size * 0.5
		dummy_stage.color = Color.BLACK
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
				new_actor.position = new_position.position
				stage_bg.remove_child(new_position)
				stage_bg.add_child(new_actor)
				stage_bg.move_child(new_actor, actor_idx)
			else:
				stage_bg.add_child(new_actor)
				if new_actor == dj: stage_bg.move_child(dj, player.get_index())

func reload_hud(custom_hud: PackedScene = null) -> void:
	var idx: int = 0
	if hud_layer.has_node("hud"):
		idx = hud_layer.get_node("hud").get_index()
		hud_layer.get_node("hud").set_process(false) # just in case
		hud_layer.get_node("hud").queue_free()
	var hud_type: String = local_settings.hud_style.to_snake_case()
	if hud_type in DEFAULT_HUDS:
		hud = DEFAULT_HUDS[hud_type].instantiate()
	else:
		var next_hud: PackedScene = custom_hud if custom_hud else chart.assets.hud
		if next_hud: hud = next_hud.instantiate()
		else: hud = DEFAULT_HUDS.classic.instantiate() # if all else fails, use the classic one.
	hud_layer.add_child(hud)
	hud_layer.move_child(hud, idx)

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
	if player and note.side == 0:
		player.sing(note.column, note.arrow.visible)
		if music: music.stream.set_sync_stream_volume(1, linear_to_db(1.0))
	if note.can_splash(): note.display_splash()
	# kill everyone, and everything in your path
	health += (DEFAULT_HEALTH_WEIGHT * judged_tier)
	#print_debug("Health increased by ", DEFAULT_HEALTH_WEIGHT * judged_tier, "%")
	# Scoring Stuff
	local_tally.increase_score(abs_diff)
	if note.judgement.combo_break and local_tally.combo > 0:
		local_tally.breaks += 1
		local_tally.combo = 0
	local_tally.increase_combo(1)
	local_tally.update_accuracy(abs_diff)
	local_tally.update_tier_score(judged_tier)
	# Update HUD
	hud.display_judgement(note.judgement.texture)
	hud.display_combo(local_tally.combo)
	tally.merge(local_tally)
	hud.update_score_text()
	hud.update_health(health)
	kill_yourself()

func kill_yourself() -> void: # thanks Unholy
	if health <= 0: # игра окоичена!
		hud_layer.hide()
		if music: music.stop()
		print_debug("Died with a MA of ", tally.calculate_epic_ratio(), " and a PA of ", tally.calculate_sick_ratio())
		local_tally.zero()
		tally.merge(local_tally)
		hud.update_health(health)
		hud.update_score_text()
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
	local_tally.score -= 50
	local_tally.increase_misses(1) # increase by one
	local_tally.update_accuracy_counter()
	player.sing(idx, true, "miss")
	health += int(Tally.MISS_POINTS + damage_boost)
	if music: music.stream.set_sync_stream_volume(1, linear_to_db(0.0))
	if assets and assets.miss_note_sounds:
		Global.play_sfx(assets.miss_note_sounds.pick_random(), randf_range(0.1, 0.4))
	#print_debug("Health damaged by ", int(Tally.MISS_POINTS + damage_boost), "%")
	tally.merge(local_tally)
	hud.update_score_text()
	hud.update_health(health)
	kill_yourself()

func on_beat_hit(beat: float) -> void:
	if int(beat) > 0 and int(beat) % 4 == 0:
		hud_layer.scale += Vector2(hud.get_bump_scale(), hud.get_bump_scale())

func exit_game() -> void:
	if tally: # NOTE: save tally before ending later.
		#tally.save()
		tally = null
	var results: Control = DEFAULT_RESULTS_SCREEN.instantiate()
	results.process_mode = Node.PROCESS_MODE_ALWAYS
	player.play_animation("hey", true)
	hud_layer.add_child(results)
	get_tree().paused = true
