## Base Chart Format, nothing inherently special!
class_name Chart extends Resource

enum ChartType {
	DUMMY      = -1,
	GENERIC    = 0,
	FNF_LEGACY = 1,
	FNF_VSLICE = 2,
	STEPMANIA  = 3,
}

const VELOCITY_EVENTS: Array[StringName] = [
	&"Change Scroll Speed",
	#&"Increase Slider Velocity",
	#&"Set Slider Velocity",
]

## Assets used in the chart (music files, custom hud, pause menu, etc)
@export var assets: ChartAssets
## Song Name (to display in menus).
@export var name: StringName = &"Unknown"
## Song Artist (to display in menus).
@export var artist: StringName = &""
## Song Charter/Mapper (to display in menus).
@export var charter: StringName = &""
## List of notes to spawn in-game.
@export var notes: NoteCollection = NoteCollection.new()
## List of Events to be executed during the song.
@export var scheduled_events: Array[TimedEvent] = []
## List of Timing Changes in the chart,
## The first item will always be the default.
@export var timing_changes: Array[SongTimeChange] = [
	SongTimeChange.make(0.0, 100.0)
]
## Values extracted when parsing (just in case...)
@export var parsed_values: Dictionary[String, Variant] = {
	"song_name": "null",
	"difficulty": "null",
	"variation": "null",
}
## Note counter, only really useful internally
var note_counts: Array[int] = [0, 0]

## Returns the index of a BPM Change event from a timed position.
func time_bpm_change(time: float = 0.0) -> int:
	return timing_changes.find(Conductor.get_timed_change(time))

## Returns the BPM value for a BPM Change event.[br]
## Defaults to 0 for default bpm.
func get_bpm(change: int = 0) -> float: return timing_changes[change].bpm

## Returns the Time value for a BPM Change event.[br]
## Defaults to 0 for default time.
func get_bpm_time(change: int = 0) -> float: return timing_changes[change].time

## Returns a velocity change that is near the timestamp provided.
func get_velocity_change(timestamp: float) -> TimedEvent:
	var change: TimedEvent = null
	if scheduled_events.is_empty():
		push_error("Unable to get velocity change from an empty events list")
		return change
	var left: int = 0
	var right: int = Conductor.timing_changes.size() - 1
	while left <= right:
		var middle: int = (left + right)/2
		var event := scheduled_events[middle]
		if VELOCITY_EVENTS.has(event.name) and event.time <= timestamp:
			change = event
			left = middle + 1
		else:
			right = middle - 1
	return change

func bpm_changed_note_loop(fun: Callable):
	if not fun: return
	var change_index: int = 0
	var cur_time: float = 0.0
	var cur_change: SongTimeChange = timing_changes[change_index]
	for note: NoteData in notes:
		# convert notes to rows and shiit.
		var fake_bpm: float = get_bpm(change_index)
		var beat_length: float = (60.0 / fake_bpm)
		fun.call(note, fake_bpm, cur_time, beat_length)
		var changed_time: float = timing_changes[change_index].time < cur_time
		if changed_time and (change_index + 1) < timing_changes.size():
			change_index = timing_changes.find(cur_change) + 1
		cur_time += beat_length * maxf((cur_time * fake_bpm) / 60.0, 4.0) # TODO: change this.
		cur_change = timing_changes[change_index]

## Grabs how many notes, holds, and unique note patterns exist in the chart.
func get_note_quantities() -> Dictionary[String, int]:
	var quantities: Dictionary[String, int] = {
		"notes": 0, # Single Notes
		"holds": 0, # Hold Notes
		"chords": 0, # 2 or more notes at the same time with different columns.
		"jumps": 0, # 2 notes at the same time with different columns (doubles even).
		"hands": 0, # Three notes at the same time with different columns.
		"quads": 0, # Four notes at the same time with different columns.
	}
	var rows: Dictionary[int, Array] = { }
	bpm_changed_note_loop(func(note: NoteData, bpm: float, time: float, _crotchet: float) -> void:
		# convert notes to rows and shiit.
		# btw if you think I know what am doing, think again.
		var row: int = NoteData.secs_to_row(note.time, bpm)
		if not row in rows: rows[row] = []
		rows[row].append(note.column)
		if note.length > 0.0:
			quantities.holds += 1
		quantities.notes += 1
	)
	rows.sort() # should be enough to sort all keys.
	for i: int in rows.keys():
		var note_row: Array = rows[i]
		if note_row.size() > 1:
			if note_row.size() == 2: quantities.jumps += 1
			if note_row.size() == 3: quantities.hands += 1
			if note_row.size() == 4: quantities.quads += 1
			quantities.chords += 1
	return quantities

## Clear every overlapping note from the chart, only really used for fnf charts.
func clear_overlapping_notes() -> void:
	const EPSILON: float = 1e-12
	var counter: int = 0
	var total: int = 0
	var datas: Array[NoteData] = notes.get_all()
	for i: int in datas.size():
		if i == 0 or i >= datas.size():
			continue
		var cur: NoteData = datas[i]
		var prev: NoteData = datas[i - 1]
		if prev and is_equal_approx(cur.time - prev.time, EPSILON) and cur.column == prev.column and cur.side == prev.side:
			#print_debug("removed note 	at ", prev.time, " (", cur.time, ")")
			notes.remove_note_at(cur.side, i)
			counter += 1
		total += 1
	print_debug("deleted ", counter, " overlapping notes from ", total, " total notes")

func save_parsing_meta(song_name: StringName, difficulty: StringName = Global.DEFAULT_DIFFICULTY) -> void:
	parsed_values.variation = ChartAssets.solve_variation(difficulty)
	parsed_values.difficulty = difficulty
	parsed_values.song_name = song_name

## Detects a chart format and parses it.
static func detect_and_parse(song_name: StringName, difficulty: StringName = Global.DEFAULT_DIFFICULTY) -> Chart:
	var variation: String = ChartAssets.solve_variation(difficulty)
	var path: String = ChartAssets.song_path(song_name, variation, difficulty + ".json")
	var chart_type: ChartType = ChartType.DUMMY
	var chart: Chart

	if ResourceLoader.exists(path):
		chart_type = ChartType.FNF_LEGACY
	if ResourceLoader.exists(path.replace("/%s.json" % difficulty, "/chart.json")):
		chart_type = ChartType.FNF_VSLICE

	match chart_type:
		ChartType.GENERIC:
			chart = load(path)
			print_debug("Parsing generic Godot Resource as chart ", song_name, " with difficulty ", difficulty)
			chart.notes.sort_custom(NoteData.sort_by_time)
			chart.timing_changes.sort_custom(SongTimeChange.sort_by_time)
			chart.scheduled_events.sort_custom(TimedEvent.sort_by_time)
		ChartType.FNF_VSLICE:
			chart = VSliceChart.parse(song_name, difficulty, true)
			print_debug("Parsing new FNF style chart ", song_name, " with difficulty ", difficulty)
		ChartType.FNF_LEGACY:
			chart = FNFChart.parse(song_name, difficulty, true)
			print_debug("Parsing old FNF style chart ", song_name, " with difficulty ", difficulty)

	if not chart:
		chart = FNFChart.new() # make an FNFChart to avoid a metric fuckton amount of crashes.
		chart.scheduled_events.append(TimedEvent.velocity_change(0.0))
		print_debug("Unable to parse chart (", path, "), creating a dummy...")
	chart.clear_overlapping_notes()
	chart.save_parsing_meta(song_name, difficulty)
	if not chart.assets: chart.assets = ChartAssets.get_resource(chart)
	return chart

static func reset_timing_changes(changes: Array[SongTimeChange] = []) -> void:
	Conductor.timing_changes.clear()
	Conductor.timing_changes = changes
	if Conductor.timing_changes.is_empty():
		Conductor.timing_changes.append(SongTimeChange.make(0.0, 100.0)) # DUMMY
	Conductor.timing_changes.sort_custom(SongTimeChange.sort_by_time)

## Parses a chart from a resource file containing it.[br]
## This method SHOULD be overriden by other parsers.
static func parse(song_name: StringName, difficulty: StringName = Global.DEFAULT_DIFFICULTY, skip_checks: bool = false) -> Chart:
	var variation: String = ChartAssets.solve_variation(difficulty)
	var path: String = ChartAssets.song_path(song_name, variation, difficulty + ".tres")
	if not ResourceLoader.exists(path) and not skip_checks:
		path = Chart.fix_path(path) + ".tres"
		# and then if the lowercase path isn't found, just live with that.
		if not ResourceLoader.exists(path):
			return Chart.new()
	var chart: Chart = load(path)
	chart.assets = ChartAssets.get_resource(chart)
	return chart

## Fixes the chart path if its formatted differently from what charts usually use.
static func fix_path(path: String) -> String:
	# instead of enforcing lowercase paths, it is now a fallback
	path = path.to_lower().replace(" ", "-").get_basename()
	for forb: String in [".", ",", "'", "\""]:
		path = path.replace(forb, "")
	path = path.strip_edges().strip_escapes()
	return path
