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

## Assets used in the chart (music files, custom hud and noteskin, pause menu, etc)
@export var assets: ChartAssets
## Song Name (to display in menus).
@export var name: StringName = &"Unknown"
## Song Artist (to display in menus).
@export var artist: StringName = &""
## Song Charter/Mapper (to display in menus).
@export var charter: StringName = &""
## List of notes to spawn in-game.
@export var notes: Array[NoteData] = []
## List of Events to be executed during the song.
@export var scheduled_events: Array[TimedEvent] = []
## List of Timing Changes in the chart,
## The first item will always be the default.
@export var timing_changes: Array[SongTimeChange] = [
	SongTimeChange.make(0.0, 100.0)
]
## Values extracted when parsing (just in case...)
@export var parsed_values: Dictionary[String, Variant] = {
	"folder": "null",
	"file": "null",
}
## Note counter, only really useful internally
var note_counts: Array[int] = [0, 0]

## Returns the BPM value for a BPM Change event.[br]
## Defaults to 0 for default bpm.
func get_bpm(change: int = 0) -> float: return timing_changes[change].bpm

## Returns the Time value for a BPM Change event.[br]
## Defaults to 0 for default time.
func get_bpm_time(change: int = 0) -> float: return timing_changes[change].time

## Returns a velocity change that is near the timestamp provided.
func get_velocity_change(timestamp: float) -> TimedEvent:
	if scheduled_events.is_empty():
		push_error("Unable to get velocity change from an empty events list")
		return null
	var change: TimedEvent = null
	for i: TimedEvent in scheduled_events:
		if VELOCITY_EVENTS.has(i.name) and i.time >= timestamp:
			change = i
		else: # list is sorted, so exit early.
			break
	return change

## Clear every overlapping note from the chart, only really used for fnf charts.
func clear_overlapping_notes() -> void:
	pass
	#var counter: int = 0
	#var total: int = 0
	#for i: int in notes.size():
	#	if i == 0 or i >= notes.size():
	#		continue
	#	var cur: NoteData = notes[i]
	#	var prev: NoteData = notes[i - 1]
	#	const epsilon: float = 1e-12
	#	if prev and absf(cur.time - prev.time) < epsilon and cur.column == prev.column:
	#		print_debug("removed note 	at ", prev.time, " (", cur.time, ")")
	#		notes.remove_at(i)
	#		counter += 1
	#	total += 1
	#print_debug("deleted ", counter, " overlapping notes from ", total, " total notes")

## Detects a chart format and parses it.
static func detect_and_parse(song_name: StringName, difficulty: StringName = Global.DEFAULT_DIFFICULTY) -> Chart:
	# TODO: rewerite all of this ig.
	var variation: String = ChartAssets.solve_variation(difficulty)
	var path: String = "res://assets/game/songs/%s/%s/%s.json" % [ song_name, variation, difficulty ]
	if not ResourceLoader.exists(path):
		path = path.replace("/%s/" % variation, "/default/")
	
	var chart: Chart
	var chart_type: ChartType = ChartType.DUMMY
	
	if ResourceLoader.exists(path):
		chart_type = ChartType.FNF_LEGACY
	elif ResourceLoader.exists(path.replace("/%s.json" % difficulty, "/chart.json")):
		chart_type = ChartType.FNF_VSLICE

	match chart_type:
		ChartType.GENERIC:
			chart = load(path)
			print_debug("Parsing generic Godot Resource as chart ", song_name, " with difficulty ", difficulty)
			chart.notes.sort_custom(NoteData.sort_by_time)
			chart.timing_changes.sort_custom(SongTimeChange.sort_by_time)
			chart.scheduled_events.sort_custom(TimedEvent.sort_by_time)
			chart.clear_overlapping_notes()
		ChartType.FNF_VSLICE:
			chart = VSliceChart.parse(song_name, difficulty, true)
			print_debug("Parsing new FNF style chart ", song_name, " with difficulty ", difficulty)
			chart.clear_overlapping_notes()
		ChartType.FNF_LEGACY:
			chart = FNFChart.parse(song_name, difficulty, true)
			print_debug("Parsing old FNF style chart ", song_name, " with difficulty ", difficulty)
			chart.clear_overlapping_notes()
	
	if not chart:
		chart = FNFChart.new() # make an FNFChart to avoid a metric fuckton amount of crashes.
		chart.scheduled_events.append(TimedEvent.velocity_change(0.0))
		chart.assets = ChartAssets.get_resource(song_name, difficulty)
		print_debug("Unable to parse chart, creating a dummy...")
	chart.parsed_values["folder"] = Chart.fix_path(song_name)
	chart.parsed_values["file"] = difficulty
	return chart

## Parses a chart from a resource file containing it.[br]
## This method SHOULD be overriden by other parsers.
static func parse(song_name: StringName, difficulty: StringName = Global.DEFAULT_DIFFICULTY, skip_checks: bool = false) -> Chart:
	var path: String = "res://assets/game/songs/%s/default/%s.tres" % [ song_name, difficulty ]
	var variation_path: String = path.replace("/default/", "/%s/" % ChartAssets.solve_variation(difficulty))
	if ResourceLoader.exists(variation_path):
		path = variation_path
	if not ResourceLoader.exists(path) and not skip_checks:
		path = Chart.fix_path(path) + ".tres"
		# and then if the lowercase path isn't found, just live with that.
		if not ResourceLoader.exists(path):
			return Chart.new()
	var chart: Chart = load(path)
	chart.assets = ChartAssets.get_resource(song_name, difficulty)
	return chart

## Fixes the chart path if its formatted differently from what charts usually use.
static func fix_path(path: String) -> String:
	# instead of enforcing lowercase paths, it is now a fallback
	path = path.to_lower().replace(" ", "-").get_basename()
	for forb: String in [".", ",", "'", "\""]:
		path = path.replace(forb, "")
	path = path.strip_edges().strip_escapes()
	return path
