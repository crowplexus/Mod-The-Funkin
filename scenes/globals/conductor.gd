## Internal Node that manages time and game synching
## Do not use this for evil.
extends Node

## Signal fired every beat hit
signal on_beat_hit(beat: float)
## Signal fired every bar / measure hit
signal on_bar_hit(bar: float)

const BEAT_EPSILON: float = 0.0001

@onready var metronome: AudioStreamPlayer = $%"metronome"
## I wonder what this could be.
@export var play_metronome_sound: bool = false

## If the conductor is active, disables _process function when disabled,
## Which would allow you to update it manually if needed.
@export var active: bool = false:
	set(v):
		active = v
		set_process(v)
## If the playhead variable should copy the time variable.
@export var playhead_copies_time: bool = true
## Man I wonder what this could be.
var time: float = 0.0
## Time limit (in seconds).
var length: float = -1.0
## [code]time[/code] but used as a visual position (for notes, for example)
var playhead: float = 0.0
## Offset for the playhead.
var play_offset: float = 0.0
## Beats per minute.
var bpm: float = 100.0:
	set(new_bpm):
		bpm = new_bpm
		crotchet = 60.0 / bpm
## Audio Playback Speed rate.
var rate: float = 1.0:
	set(new_rate):
		AudioServer.playback_speed_scale = new_rate
		Engine.time_scale = new_rate
## Beat Length in seconds, calculated when setting the bpm.
var crotchet: float = 0.0
## List of Timing Changes.
var timing_changes: Array[SongTimeChange] = [
	SongTimeChange.make(0.0, 100.0) # DUMMY
]

## Current song beat.
var current_beat: float = 0.0
	#get: return snappedf(current_beat, 0.01)
## Current song bar.
var current_bar: float = 0.0
	#get: return snappedf(current_bar, 0.01)

var _prev_beat: float = 0.0
var _prev_time: float = 0.0


## Resets the Conductor's values, call only when needed,
## as it can cause issues otherwise.
func reset(_bpm: float = 100.0, _active: bool = false) -> void:
	play_offset = 0.0
	active = _active
	bpm = _bpm
	set_time(0.0)

func set_time(new_time: float) -> void:
	time = new_time
	_prev_time = new_time
	current_beat = (new_time * bpm) / 60.0
	current_bar = 0.0#current_beat * 4.0
	_prev_beat = current_beat


func update(new_time: float) -> void:
	time = new_time # usually would be incremented by delta but I need this to be *set* for synching purposes
	if playhead_copies_time: playhead = time + play_offset
	
	var ctc: SongTimeChange = Conductor.get_timed_change(time)
	if bpm != ctc.bpm:
		#print_debug("Changed BPM from ", bpm, " to ", ctc.bpm, " at timestamp ", time)
		bpm = ctc.bpm
	
	var beat_dt: float = ctc.calculate_beat_delta(time - _prev_time)
	current_bar += beat_dt * 4.0
	current_beat += beat_dt
	if int(_prev_beat) < int(current_beat):
		if play_metronome_sound: metronome.play(0.0)
		if int(current_beat) % 4 == 0:
			on_bar_hit.emit(current_bar)
		on_beat_hit.emit(current_beat)
		_prev_beat = current_beat
	_prev_time = time

## Returns a time change that is near the timestamp provided.
func get_timed_change(timestamp: float) -> SongTimeChange:
	if Conductor.timing_changes.is_empty():
		push_error("No Timing Changes are available, how did you do that? it always has at least one")
		return null
	var change: SongTimeChange = Conductor.timing_changes[0]
	if timestamp <= 0.0: return change # This is, most likely, the first change.
	for i: SongTimeChange in Conductor.timing_changes:
		if i.time >= timestamp: # NOTE: Test with time parameter being exactly at a timing change, or after all timing changes
			change = i
		else: # list is sorted, so exit early.
			break
	return change

## Converts Beats per minute to seconds.
func get_bps(bpm_value: float) -> float:
	return 60.0 / bpm_value

## Returns the maximum amount of beats depending on the length given
func get_total_beats(song_length: float = 0.0, beats_per_minute: float = 100.0) -> float:
	return (beats_per_minute / 60.0) * song_length

func _ready() -> void:
	set_process_input(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
	set_physics_process_internal(false)
	set_process_internal(false)
	set_physics_process(false)

func _process(_delta: float) -> void:
	if active: update(time + _delta)
