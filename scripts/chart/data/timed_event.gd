### Timed Events are very basic event types that contain a [code]time[/code]
### field, which is used to trigger the event during gameplay.
class_name TimedEvent extends Resource

@export var name: StringName ## Name of the event.
@export var time: float ## Time (in seconds).
@export var eload: Callable ## Function to run when the event loads.
@export var efire: Callable ## Function to run whenever the event gets fired.
@export var values: Dictionary = {} ## Internal values in the event.
var was_fired: bool = false ## Internal value, indicates that the event has already been fired, so no point in doing it again.

func _to_string() -> String:
	return "[%s, %s, %s]" % [ name, time, values ]

### Returns a Velocity Change event.
static func velocity_change(_time: float, speed: float = 1.0) -> TimedEvent:
	var vc: = TimedEvent.new()
	vc.name = &"Change Scroll Speed"
	vc.values.speed = speed
	vc.time = _time
	return vc

### Returns a BPM Change event.
#static func bpm_change(_time: float, bpm: float = 100.0) -> TimedEvent:
#	var vc: = TimedEvent.new()
#	vc.name = &"BPM Change"
#	vc.time = _time
#	vc.values.bpm = bpm
#	vc.efire = func() -> int:
#		Conductor.bpm = vc.values.bpm
#		return vc.values.bpm
#	return vc

static func sort_by_time(one: TimedEvent, two: TimedEvent) -> int:
	return one.time < two.time
