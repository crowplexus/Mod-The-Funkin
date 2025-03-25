## Base Chart Format, nothing inherently special!
class_name Chart
extends Resource

const VELOCITY_EVENTS: Array[StringName] = [
	&"Change Scroll Speed",
	#&"Increase Slider Velocity",
	#&"Set Slider Velocity",
]

## Assets used in the chart (music files, custom hud and noteskin, pause menu, etc)
@export var assets: ChartAssets
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
	var change: TimedEvent = scheduled_events[0]
	for i: TimedEvent in scheduled_events:
		if VELOCITY_EVENTS.has(i.name) and i.time >= timestamp:
			change = i
		else: # list is sorted, so exit early.
			break
	return change

## Parses a chart from a resource file containing it.[br]
## This method SHOULD be overriden by other parsers.
static func parse(song_name: StringName, difficulty: StringName = "normal") -> Chart:
	var path: String = "res://assets/game/songs/%s/charts/%s.tres" % [ song_name, difficulty ]
	var song: String = song_name
	if not ResourceLoader.exists(path):
		path = Chart.fix_path(path) + ".json"
		song = Chart.fix_path(song)
		# and then if the lowercase path isn't found, just live with that.
		if not ResourceLoader.exists(path):
			return Chart.new()
	
	var chart: Chart = load(path)
	chart.assets = Chart.get_assets_resource("res://assets/game/songs/%s/assets.tres" % song)
	chart.parsed_values["folder"] = song_name
	chart.parsed_values["file"] = difficulty
	return chart

## Fixes the chart path if its formatted differently from what charts usually use.
static func fix_path(path: String) -> String:
	# instead of enforcing lowercase paths, it is now a fallback
	path = path.to_lower().replace(" ", "-").get_basename()
	for forb: String in [".", ",", "'", "\""]:
		path = path.replace(forb, "")
	path = path.strip_edges().strip_escapes()
	return path

## Returns an assets resource from the specified path (if it exists)[br]
## Will return a a default resource on fail.
static func get_assets_resource(path: String) -> ChartAssets:
	if not ResourceLoader.exists(path):
		path = Chart.fix_path(path)
		if not ResourceLoader.exists(path):
			return Global.DEFAULT_CHART_ASSETS
	return load(path)
