## Chart Format for Friday Night Funkin' (0.3+)
class_name VSliceChart extends Chart

const DUMMY_METADATA: Dictionary[String, Variant] = {
	"version": "2.2.4",
	"songName": "Undefined",
	"artist": "Unknown",
	"charter": "Unknown",
	"playData": {
		"difficulties": ["normal"],
		"characters": {
		  "player": "face",
		  "girlfriend": "face",
		  "opponent": "face",
		  "instrumental": "default"
		},
		"stage": "mainStage",
		"noteStyle": "funkin",
		"ratings": { "default": 0 },
		"album": "unknown",
		"previewStart": 0,
		"previewEnd": 0
	},
	"generatedBy": "Dummy Metadata",
	"timeFormat": "ms",
	"timeChanges": [
		{ "t": 0, "b": 0, "bpm": 100, "n": 4, "d": 4, "bt": [4, 4, 4, 4] }
	]
}

## Background to load before the characters
@export var stage: PackedScene = null
## Characters to load, leave "null" to not load[br]Order: [Player, Enemy, DJ]
@export var characters: Array[PackedScene] = [null, null, null,]

## Parses a chart from a JSON file using the new FNF chart format
static func parse(song_name: StringName, difficulty: StringName = Global.DEFAULT_DIFFICULTY, skip_checks: bool = false) -> Chart:
	var path: String = ChartAssets.song_path(song_name, ChartAssets.solve_variation(difficulty), "chart.json")
	if not ResourceLoader.exists(path) and not skip_checks:
		path = Chart.fix_path(path) + ".json"
		# and then if the lowercase path isn't found, just live with that.
		if not ResourceLoader.exists(path):
			print_debug("Failed to parse chart \"%s\" [Difficulty: %s]" % [ song_name, difficulty ])
			return Chart.new()
	return VSliceChart.parse_from_string(load(path).data, song_name, difficulty)

static func get_vslice_metadata(song_name: String, difficulty: StringName = Global.DEFAULT_DIFFICULTY) -> Dictionary:
	var path: String = ChartAssets.song_path(song_name, ChartAssets.solve_variation(difficulty), "metadata.json")
	if not ResourceLoader.exists(path):
		path = Chart.fix_path(path) + ".json"
		if not ResourceLoader.exists(path):
			print_debug("Failed to find metadata \"%s\" [Difficulty: %s]" % [ song_name, difficulty ])
			return DUMMY_METADATA
	var file: Dictionary = load(path).data
	return file if file else DUMMY_METADATA

## Parses a json string as a chart.
static func parse_from_string(json: Dictionary, song_name: StringName, difficulty: StringName = Global.DEFAULT_DIFFICULTY) -> VSliceChart:
	var meta: Dictionary = get_vslice_metadata(song_name, difficulty)
	var chart: VSliceChart = VSliceChart.new()
	# set stage to spawn before gameplay.
	if "songName" in meta: chart.name = meta["songName"]
	if "artist" in meta: chart.artist = meta.artist
	if "charter" in meta: chart.charter = meta.charter
	if "playData" in meta:
		var play_data: Dictionary = meta["playData"]
		if "stage" in play_data:
			var new_stage: String = str(play_data.stage).to_snake_case()
			var path: String = "res://scenes/gameplay/stages/%s.tscn" % new_stage
			if ResourceLoader.exists(path):
				chart.stage = load(path)
			else:
				print_debug("tried loading stage at ", path, " which leads to a file that doesn't exist.")
			chart.parsed_values.stage = new_stage
		# set characters to spawn before gameplay.
		if "characters" in play_data:
			var players: PackedStringArray = ["player", "opponent", "girlfriend"]
			for prop: String in players:
				if not prop in play_data.characters:
					continue
				var i: int = players.find(prop)
				var char_name: StringName = play_data.characters[prop]
				var path: String = "res://scenes/gameplay/characters/%s.tscn" % char_name
				if ResourceLoader.exists(path): chart.characters[i] = load(path)
				else: chart.characters[i] = load(path.replace(play_data.characters[prop], Actor2D.PLACEHOLDER_NAME))
				# save raw character names for the sake of loading assets later and blah blah blah.
				if not "characters" in chart.parsed_values: chart.parsed_values.characters = []
				chart.parsed_values.characters.append(char_name)
	
	# set scroll speed
	var scroll_speed: float = 1.0
	if "scrollSpeed" in json:
		var scroll_difficulty: String = difficulty.to_lower().strip_escapes().strip_edges()
		if not scroll_difficulty in json["scrollSpeed"]:
			scroll_difficulty = "default"
		if scroll_difficulty in json["scrollSpeed"]:
			scroll_speed = float(json["scrollSpeed"][scroll_difficulty])
	chart.scheduled_events.append(TimedEvent.velocity_change(-2.0, scroll_speed, true)) # default speed
	# create notes.
	var note_difficulty: String = difficulty.to_lower().strip_escapes().strip_edges()
	if not note_difficulty in json.notes:
		note_difficulty = "default"
	if "notes" in json:
		if note_difficulty in json.notes: # default or current difficulty.
			var max_columns: int = 4
			var fake_bpm: float = chart.get_bpm()
			var fake_crotchet: float = (60.0 / fake_bpm)
			var song_notes: Array = json.notes[note_difficulty]
			var fake_timer: float = 0.0
			var signature: float = 4.0
			for note: Dictionary in song_notes:
				var new_note: NoteData = NoteData.from_dictionary(note, max_columns)
				if new_note.column > -1:
					new_note.column = int(new_note.column % max_columns)
					if new_note.side > chart.note_counts.size():
						chart.note_counts.append(0)
					chart.note_counts[new_note.side] += 1
					chart.notes.append(new_note)
				else:
					push_warning("Unable to create note at ", fake_timer)
			fake_timer += fake_crotchet * signature
	# create events.
	if "events" in json:
		var song_events: Array
		if json.events is Dictionary and note_difficulty in song_events:
			song_events = json.events[note_difficulty]
		elif json.events is Array:
			song_events = json.events
		for event: Dictionary in song_events:
			if "t" in event and "e" in event: chart.scheduled_events.append(make_event(event.t, event.e, event.v))
	# move metadata values
	if "artist" in meta: chart.parsed_values.artist = meta.artist
	if "charter" in meta: chart.parsed_values.charter = meta.charter
	if "version" in meta: chart.parsed_values.version = meta.version
	if "timeChanges" in meta:
		chart.timing_changes.clear()
		var time_changes: Array = meta["timeChanges"]
		for change: Dictionary in time_changes:
			if "t" in change and "bpm" in change:
				chart.timing_changes.append(SongTimeChange.make(change.t, change.bpm))
	
	chart.notes.sort_custom(NoteData.sort_by_time)
	chart.timing_changes.sort_custom(SongTimeChange.sort_by_time)
	chart.scheduled_events.sort_custom(TimedEvent.sort_by_time)
	
	return chart

static func make_event(time: float, event_name: StringName = &"_", value: Variant = null) -> TimedEvent:
	var event: TimedEvent = TimedEvent.new()
	event.time = time * 0.001
	match event_name:
		&"PlayAnimation":
			event.name = &"Play Animation"
			if value is int or value is float: event.values.target = int(value)
			elif value is Dictionary: event.values.assign(value)
			if "target" in event.values:
				match event.values.target:
					"boyfriend", "bf", "player", "0": event.values.target = 0
					"dad", "opponent", "enemy", "1": event.values.target = 1
					"gf", "dj", "metronome", "2": event.values.target = 2
			if not "force" in event.values: event.values.force = false
			if not "cooldown" in event.values: event.values.cooldown = 0.0
			event.efire = func() -> void:
				TimedEvent.play_animation_event(event.values.anim,
					event.values.force, event.values.target, event.values.cooldown)
		&"FocusCamera":
			event.name = &"Change Camera Focus"
			if value is int or value is float: event.values.char = value
			elif value is Dictionary: event.values.assign(value)
			if "char" in event.values: event.values.char = int(event.values.char)
			var x_pos: float = 0.0 if not "x" in event.values else event.values.x
			var y_pos: float = 0.0 if not "y" in event.values else event.values.y
			event.efire = func() -> void: TimedEvent.focus_camera_event(event.values.char, x_pos, y_pos)
		&"ZoomCamera":
			event.name = &"Change Camera Zoom"
			if value is float: event.values.zoom = value
			elif value is Dictionary: event.values.assign(value)
			if "zoom" in event.values: event.values.zoom = float(event.values.zoom)
			event.efire = func() -> void: TimedEvent.zoom_camera_event(event.values.zoom)
		_:
			event.name = event_name
			if value is Dictionary: event.values.assign(value)
			else: event.values.v = value
	return event
