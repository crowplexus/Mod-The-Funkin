## Chart Format for Friday Night Funkin' (0.2.7.1)[br]
## also includes support for any of its children formats (i.e: Psych Engine)
class_name FNFChart extends Chart

## Background to load before the characters
@export var stage: PackedScene = null
## Characters to load, leave "null" to not load[br]Order: [Player, Enemy, DJ]
@export var characters: Array[PackedScene] = [null, null, null]

## Parses a chart from a JSON file using the original FNF chart format or similar
static func parse(song_name: StringName, difficulty: StringName = Global.DEFAULT_DIFFICULTY, skip_checks: bool = false) -> Chart:
	var variation: String = ChartAssets.solve_variation(difficulty)
	var path: String = ChartAssets.song_path(song_name, variation, "/%s.json" % difficulty)

	if not ResourceLoader.exists(path) and not skip_checks:
		path = Chart.fix_path(path) + ".json"
		# and then if the lowercase path isn't found, just live with that.
		if not ResourceLoader.exists(path):
			# last resort, use default difficulty
			path = path.replace(path.get_file().get_basename(), Global.DEFAULT_DIFFICULTY.to_lower())
		if not ResourceLoader.exists(path):
			print_debug("Failed to parse chart \"%s\" [Difficulty: %s]" % [ song_name, difficulty ])
			return Chart.new()
	
	return FNFChart.parse_from_string(load(path).data)

## Parses a json string as a chart.
static func parse_from_string(json: Dictionary) -> FNFChart:
	var chart: FNFChart = FNFChart.new()
	var legacy_mode: bool = json.song is Dictionary
	var chart_dict: Dictionary = json.song if legacy_mode else json
	var is_psych: bool = false
	if "stage" in chart_dict:
		var new_stage: String = str(chart_dict.stage).to_snake_case()
		match new_stage:
			"stage": new_stage = "main_stage"
		var path: String = "res://scenes/gameplay/stages/%s.tscn" % new_stage
		if ResourceLoader.exists(path):
			chart.stage = load(path)
		else:
			print_debug("tried loading stage at ", path, " which leads to a file that doesn't exist.")
		chart.parsed_values.stage = new_stage
	var players: PackedStringArray = ["player1", "player2", "gfVersion"]
	for prop: String in players:
		if not prop in chart_dict:
			continue
		var i: int = players.find(prop)
		var char_name: StringName = chart_dict[prop]
		var path: String = "res://scenes/gameplay/characters/%s.tscn" % char_name
		if path.contains("gfVersion") and not ResourceLoader.exists(path): path = path.replace("gfVersion", "player3")
		if ResourceLoader.exists(path): chart.characters[i] = load(path)
		else: chart.characters[i] = load(path.replace(char_name, Actor2D.PLACEHOLDER_NAME))
		# save raw character names for the sake of loading assets later and blah blah blah.
		if not "characters" in chart.parsed_values: chart.parsed_values.characters = []
		chart.parsed_values.characters.append(char_name)
	
	chart.timing_changes[0].bpm = chart_dict.bpm if "bpm" in chart_dict else 100.0
	chart.name = chart_dict.song
	if "artist" in chart_dict: chart.artist = chart_dict.artist
	if "charter" in chart_dict: chart.charter = chart_dict.charter
	
	var was_must_hit: int = -1
	var fake_bpm: float = chart.get_bpm()
	var fake_crotchet: float = (60.0 / fake_bpm)
	var fake_timer: float = 0.0
	var max_columns: int = 4
	
	for measure: Dictionary in chart_dict["notes"]:
		if not "sectionNotes" in measure: measure["sectionNotes"] = []
		if not "mustHitSection" in measure: measure["mustHitSection"] = false
		if not "changeBPM" in measure: measure["changeBPM"] = false
		var must_hit_section: int = int(not measure["mustHitSection"])
		var section_beats: float = 4.0
		if "sectionBeats" in measure:
			section_beats = float(measure["sectionBeats"])
			if not is_psych and measure and "format" in chart_dict and str(chart_dict.format).find("psych_v1") > -1:
				is_psych = true
		
		if was_must_hit != must_hit_section:
			was_must_hit = must_hit_section
			var focus_change: = TimedEvent.new()
			focus_change.name = &"Change Camera Focus"
			if "gfSection" in measure and measure["gfSection"] == true:
				focus_change.values.char = 2 # Center (GF)
			else:
				focus_change.values.char = was_must_hit
			focus_change.time = fake_timer
			focus_change.efire = func() -> void: TimedEvent.focus_camera_event(focus_change.values.char)
			chart.scheduled_events.append(focus_change)
		
		for song_note: Array in measure["sectionNotes"]:
			var column: int = int(song_note[1])
			if column <= -1:
				chart.load_psych_events(song_note)
				continue
			var swag_note: NoteData = NoteData.from_array(song_note, max_columns)
			if legacy_mode:
				swag_note.side = int(must_hit_section)
				if column % (max_columns * 2) >= max_columns:
					swag_note.side = int(not must_hit_section)
			if is_psych and swag_note.side < 2:
				swag_note.side = 1 - swag_note.side
			if swag_note.side > chart.note_counts.size():
				chart.note_counts.append(0)
			if song_note.size() > 3: # i completely forgot this exists.
				chart.load_psych_notetypes_as_events(song_note, swag_note.side)
				if str(song_note[3]) == "Alt Animation": swag_note.anim_suffix = "-alt"
			chart.note_counts[swag_note.side] += 1
			chart.notes.add_note(swag_note)
		
		if measure["changeBPM"] == true and fake_bpm != measure.bpm:
			fake_bpm = measure.bpm
			fake_crotchet = (60.0 / measure.bpm)
			print_debug("Pushed change at ", fake_timer, " which changes the bpm to ", measure.bpm)
			chart.timing_changes.append(SongTimeChange.make(fake_timer, measure.bpm))
		
		fake_timer += fake_crotchet * section_beats
	
	var speed: float = chart_dict.speed if "speed" in chart_dict else 1.0
	var scroll_speed_event: = TimedEvent.velocity_change(-2.0, speed, true)
	chart.scheduled_events.append(scroll_speed_event)
	
	chart.timing_changes.sort_custom(SongTimeChange.sort_by_time)
	chart.scheduled_events.sort_custom(TimedEvent.sort_by_time)
	
	return chart

## For Psych Engine Event Support.
func load_psych_events(event_note: Array) -> void:
	#var event_name: StringName
	#var time: float = 0.0
	if event_note[1] is Array: # new psych format
		for sub_event: Array in event_note[1]:
			var event: TimedEvent = TimedEvent.new()
			event.name = StringName(sub_event[0])
			event.time = float(event_note[1][0])
			event.values.assign({"v1": sub_event[1], "v2": sub_event[2]})
			scheduled_events.append(event)
	else: # legacy event
		var event: TimedEvent = TimedEvent.new()
		event.name = StringName(event_note[2])
		event.time = float(event_note[0] * 0.001)
		event.values.assign({"v1": event_note[3], "v2": event_note[4]})
		scheduled_events.append(event)

func load_psych_notetypes_as_events(note: Array, side: int) -> void:
	match str(note[3]):
		"Hey!":
			var hey_note: = TimedEvent.new()
			hey_note.name = &"Play Animation"
			hey_note.time = float(note[0]) * 0.001
			hey_note.efire = func() -> void:
				TimedEvent.play_animation_event("hey", true, side)
			scheduled_events.append(hey_note)

## For Kade Engine BPM Change Events.
func load_kade_bpm_changes() -> void:
	pass

## For Andromeda Engine Velocity Change Events.
func load_andromeda_velocity_changes() -> void:
	# ADAPTED FROM QUAVER!!!
	# https://github.com/Quaver/Quaver
	pass
