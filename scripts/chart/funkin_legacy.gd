## Chart Format for Friday Night Funkin' (0.2.7.1),
## also includes support for any of its children formats (i.e: Psych Engine)
class_name FNFChart
extends Chart

## Background to load before the characters
@export var stage: PackedScene = null
## Characters to load, leave "null" to not load[br]Order: [Player, Enemy, DJ]
@export var characters: Array[PackedScene] = [
	preload("res://scenes/gameplay/characters/face.tscn"),
	preload("res://scenes/gameplay/characters/face.tscn"),
	preload("res://scenes/gameplay/characters/face.tscn"),
]

## Parses a chart from a JSON file using the original FNF chart format or similar
static func parse(song_name: StringName, difficulty: StringName = Global.DEFAULT_DIFFICULTY, skip_checks: bool = false) -> Chart:
	var variation: String = ChartAssets.solve_variation(difficulty)
	var path: String = ChartAssets.solve_song_path(song_name, variation) + "/%s.json" % difficulty

	if not ResourceLoader.exists(path) and not skip_checks:
		path = Chart.fix_path(path) + ".json"
		# and then if the lowercase path isn't found, just live with that.
		if not ResourceLoader.exists(path):
			# last resort, use default difficulty
			path = path.replace(path.get_file().get_basename(), Global.DEFAULT_DIFFICULTY.to_lower())
		if not ResourceLoader.exists(path):
			print_debug("Failed to parse chart \"%s\" [Difficulty: %s]" % [ song_name, difficulty ])
			return Chart.new()
	
	var chart: FNFChart = FNFChart.parse_from_string(load(path).data)
	chart.assets = ChartAssets.get_resource(song_name, difficulty)
	return chart

## Parses a json string as a chart.
static func parse_from_string(json: Dictionary) -> FNFChart:
	var chart: FNFChart = FNFChart.new()
	var legacy_mode: bool = json.song is Dictionary
	var chart_dict: Dictionary = json.song if legacy_mode else json
	# i hate my lifeeee FUCK OFF SHADOWMARIO
	var is_psych: bool = legacy_mode and "format" in chart_dict and chart_dict.format == "psych_v1_convert"
	chart.scheduled_events.append(TimedEvent.velocity_change(0.0, 1.0))
	
	if "stage" in chart_dict:
		var new_stage: String = str(chart_dict.stage).to_snake_case()
		match new_stage:
			"stage": new_stage = "main_stage"
		var path: String = "res://scenes/gameplay/stages/%s.tscn" % new_stage
		if ResourceLoader.exists(path):
			chart.stage = load(path)
		else:
			print_debug("tried loading stage at ", path, " which leads to a file that doesn't exist.")
	var players: PackedStringArray = ["player1", "player2", "gfVersion"]
	for prop: String in players:
		if not prop in chart_dict:
			continue
		var i: int = players.find(prop)
		var path: String = "res://scenes/gameplay/characters/%s.tscn" % chart_dict[prop]
		if path.contains("gfVersion") and not ResourceLoader.exists(path): path = path.replace("gfVersion", "player3")
		if ResourceLoader.exists(path): chart.characters[i] = load(path)
	
	if "speed" in chart_dict: chart.scheduled_events[0].values.speed = chart_dict.speed
	if "bpm" in chart_dict: chart.timing_changes[0].bpm = chart_dict.bpm

	var fake_bpm: float = chart.get_bpm()
	var fake_crotchet: float = (60.0 / fake_bpm)
	var fake_timer: float = 0.0
	var max_columns: int = 4
	
	var was_must_hit: bool = false
	
	for measure: Dictionary in chart_dict["notes"]:
		if not "sectionNotes" in measure: measure["sectionNotes"] = []
		if not "mustHitSection" in measure: measure["mustHitSection"] = false
		if not "changeBPM" in measure: measure["changeBPM"] = false
		if not "bpm" in measure: measure["bpm"] = fake_bpm
		var must_hit_section: bool = measure["mustHitSection"]
		
		if must_hit_section != was_must_hit:
			was_must_hit = must_hit_section
			var focus_change: = TimedEvent.new()
			focus_change.name = &"Change Camera Focus"
			focus_change.values.char = 0 if must_hit_section else 1
			chart.scheduled_events.append(focus_change)
		
		for song_note: Array in measure["sectionNotes"]:
			var column: int = int(song_note[1])
			if column <= -1:
				# psych events, do something here later
				continue
			var swag_note: NoteData = NoteData.from_array(song_note)
			if legacy_mode:
				swag_note.side = int(must_hit_section)
				if column % (max_columns if is_psych else max_columns * 2) >= max_columns:
					swag_note.side = int(not must_hit_section)
			#if swag_note.length > 0.0:
			#	swag_note.length = swag_note.length / (fake_crotchet * 0.25)
			chart.notes.append(swag_note)
		
		if measure["changeBPM"] == true and fake_bpm != measure.bpm:
			fake_bpm = measure.bpm
			fake_crotchet = (60.0 / measure.bpm)
			print_debug("Pushed change at ", fake_timer, " which changes the bpm to ", measure.bpm)
			chart.timing_changes.append(SongTimeChange.make(fake_timer, measure.bpm))
		
		fake_timer += fake_crotchet / 4.0
	
	chart.notes.sort_custom(NoteData.sort_by_time)
	chart.timing_changes.sort_custom(SongTimeChange.sort_by_time)
	chart.scheduled_events.sort_custom(TimedEvent.sort_by_time)
	Conductor.timing_changes = chart.timing_changes.duplicate()
	
	#var ghosts: int = 0
	#var total_notes_collected: int = 0
	#for i: int in chart.notes.size():
	#	if i == 0: continue
	#	var cur: NoteData = chart.notes[i]
	#	var prev: NoteData = chart.notes[i - 1]
	#	if prev and is_equal_approx(cur.time, prev.time) and cur.column == prev.column:
	#		chart.notes.remove_at(i)
	#		ghosts += 1
	#	total_notes_collected += 1
	#print_debug("deleted ", ghosts, " ghost notes from ", total_notes_collected, " total notes")
	
	return chart

## For Psych Engine Event Support.
func load_psych_event() -> void:
	pass

## For Kade Engine BPM Change Events.
func load_kade_bpm_changes() -> void:
	pass

## For Andromeda Engine Velocity Change Events.
func load_andromeda_velocity_changes() -> void:
	# ADAPTED FROM QUAVER!!!
	# https://github.com/Quaver/Quaver
	pass
