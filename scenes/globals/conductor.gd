## Internal Node that manages time and game synching
## Do not use this for evil.
extends Node

signal on_beat_hit(beat: float) ## Signal fired every beat hit
signal on_bar_hit(bar: float) ## Signal fired every bar / measure hit
signal music_looped(times: int) ## Signal fired every time the bound song loops.

@onready var metronome: AudioStreamPlayer = $%"metronome"
@onready var bound_music: AudioStreamPlayer = $"%bound_music"
@export var play_metronome_sound: bool = false ## I wonder what this could be.
var current_stream_is_looped: bool = false
var _times_looped: int = 0

## If the conductor is active, disables _process function when disabled,
## Which would allow you to update it manually if needed.
@export var active: bool = true:
	set(v):
		active = v
		set_process(v)
## If the playhead variable should copy the time variable.
@export var pause_playhead: bool = true
## Man I wonder what this could be.
var time: float = 0.0
## Time limit (in seconds).
var length: float = -1.0
## [code]time[/code] but used as a visual position (for notes, for example)
var playhead: float = 0.0
## Beats per minute.
var bpm: float = 100.0:
	set(new_bpm):
		bpm = new_bpm
		crotchet = 60.0 / new_bpm
## Audio Playback Speed rate.
var rate: float = 1.0:
	set(new_rate):
		rate = new_rate
		AudioServer.playback_speed_scale = new_rate
		#AudioServer.get_bus_effect(1, 1).pitch_scale = new_rate
		Engine.time_scale = new_rate
## Beat Length in seconds, calculated when setting the bpm.
var crotchet: float = 0.0
## List of Timing Changes.
var timing_changes: Array[SongTimeChange] = [
	SongTimeChange.make(0.0, 100.0) # DUMMY
]

var current_beat: float = 0.0 ## Current song beat.
var current_bar: float = 0.0 ## Current song bar / measure.

var _prev_beat: float = 0.0
var _prev_bar : float = 0.0
var _prev_time: float = 0.0

## Resets the Conductor's values, call only when needed,
## as it can cause issues otherwise.
func reset(_bpm: float = 100.0, _active: bool = false) -> void:
	active = _active
	bpm = _bpm
	set_time(0.0)

## Sets the Conductor's time and related values.
func set_time(new_time: float = 0.0) -> void:
	_prev_time = new_time
	current_beat = (new_time * bpm) / 60.0
	current_bar = current_beat * 4.0
	_prev_beat = current_beat
	_prev_bar = current_bar
	time = new_time
	update_beats()

func _ready() -> void:
	set_process_input(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
	set_physics_process_internal(false)
	set_process_internal(false)
	set_physics_process(false)

func _process(_delta: float) -> void:
	if active and not get_tree().paused:
		if bound_music and bound_music.playing:
			Conductor.update_bound_music()
		else:
			Conductor.update(time + _delta)

## Updates the Conductor's values, call only when needed,
## as it can cause issues otherwise.
func update(new_time: float) -> void:
	time = new_time # usually would be incremented by delta but I need this to be *set* for synching purposes
	if pause_playhead: playhead = time
	
	var ctc: SongTimeChange = Conductor.get_timed_change(time)
	if bpm != ctc.bpm:
		#print_debug("Changed BPM from ", bpm, " to ", ctc.bpm, " at timestamp ", time)
		bpm = ctc.bpm
	var beat_dt: float = ctc.calculate_beat_delta(time - _prev_time)
	current_bar += beat_dt * 4.0
	current_beat += beat_dt
	update_beats()
	_prev_time = time

func update_beats() -> void:
	if floori(current_beat) > floori(_prev_beat):
		for i: int in range(_prev_beat,current_beat):
			on_beat_hit.emit(i)
		_prev_beat = current_beat
	if floori(current_bar) > floori(_prev_bar):
		for i: int in range(_prev_bar,current_bar):
			on_bar_hit.emit(i)
		_prev_bar = current_bar

## Syncs the Conductor's time to the bound music stream.
func update_bound_music() -> void:
	if play_metronome_sound and floori(current_beat) > floori(_prev_beat):
		metronome.play(0.0)
	if bound_music and bound_music.stream and Conductor.active:
		var music_time: float = bound_music.get_playback_position()
		if current_stream_is_looped and Conductor.time >= Conductor.length:
			_times_looped += 1
			Conductor.set_time(0.0)
			music_looped.emit(_times_looped)
		Conductor.update(music_time)

#region Bound Music, These functions aren't needed but have null checks to prevent errors.

## Seeks the music stream of the Conductor.
func seek_music(target_time: float = 0.0) -> void:
	if bound_music: bound_music.seek(target_time)

## Plays the music stream of the Conductor.
func play_music(start_time: float = 0.0, volume_linear: float = 1.0, looped: bool = true) -> void:
	if bound_music and bound_music.stream:
		bound_music.stream.get_sync_stream(0).loop = looped
		bound_music.volume_linear = volume_linear
		current_stream_is_looped = looped
		bound_music.play(start_time)
		_times_looped = 0

## Sets the volume of the music stream of the Conductor.
func set_music_volume(volume_linear: float, stream: int = -1) -> void:
	if bound_music and bound_music.stream:
		if stream < 0 or stream > bound_music.stream.stream_count:
			bound_music.volume_linear = volume_linear
		else:
			bound_music.stream.set_sync_stream_volume(stream, linear_to_db(volume_linear))

## Toggles whether the song should loop.
func toggle_music_looping(value: bool = false) -> void:
	if bound_music and bound_music.stream:
		bound_music.stream.get_sync_stream(0).loop = value
		current_stream_is_looped = value

## Pauses or unpauses the music stream of the Conductor.
func toggle_pause_music(value: bool = false) -> void:
	if bound_music: bound_music.stream_paused = not value

## Stops the music stream of the Conductor.
func stop_music() -> void:
	if bound_music: bound_music.stop()

func get_main_stream() -> AudioStream:
	return bound_music.stream.get_sync_stream(0) if bound_music and bound_music.stream else null

## Sets the music stream of the Conductor.
func set_music_stream(stream: AudioStream) -> void:
	if bound_music:
		bound_music.stream.set_sync_stream(0, stream)
		if stream: Conductor.length = stream.get_length()

## Clears all music streams from the Conductor.
func clear_music_streams() -> void:
	if bound_music and bound_music.stream:
		bound_music.stop()
		for i: int in bound_music.stream.stream_count:
			bound_music.stream.set_sync_stream(i, null)

## Returns whether music is currently playing.
func is_music_playing() -> bool:
	return bound_music and bound_music.playing

## Returns the current music time.
func get_music_time() -> float:
	var music_time: float = bound_music.get_playback_position() if bound_music else 0.0
	return music_time + AudioServer.get_time_since_last_mix()

## Loads a chart's music into the Conductor.
func load_chart_music(chart: Chart) -> void:
	if chart.assets and chart.assets.instrumental:
		Conductor.bound_music.stream.set_sync_stream(0, chart.assets.instrumental)
		Conductor.bound_music.stream.get_sync_stream(0).loop = false
		if chart.assets.vocals:
			for i: int in chart.assets.vocals.size():
				Conductor.bound_music.stream.set_sync_stream(i+1, chart.assets.vocals[i])
				Conductor.bound_music.stream.get_sync_stream(i+1).loop = false
		Conductor.length = chart.assets.instrumental.get_length()

#endregion

## Returns a time change that is near the timestamp provided.
func get_timed_change(timestamp: float) -> SongTimeChange:
	if Conductor.timing_changes.is_empty():
		push_error("No Timing Changes are available, how did you do that? it always has at least one")
		return null
	var change: SongTimeChange = Conductor.timing_changes[0]
	if timestamp <= 0.0: return change # This is, most likely, the first change.
	var left: int = 0
	var right: int = Conductor.timing_changes.size() - 1
	while left <= right:
		var middle: int = (left + right)/2
		var mid_change: SongTimeChange = Conductor.timing_changes[middle]
		if mid_change.time <= timestamp:
			change = mid_change
			left = middle + 1
		else:
			right = middle - 1
	return change

#region Tooling and Stchuff
## Converts time (in seconds) to a beat value.
func get_beat(p_time: float = Conductor.time, p_bpm: float = Conductor.bpm) -> float:
	return (p_time * p_bpm) / 60.0

## Converts beats to a time value (in seconds).
func get_time(p_beat: float = Conductor.current_beat, p_bpm: float = Conductor.bpm) -> float:
	return (p_beat / 60.0) * p_bpm

## Converts time (in seconds) to a 16th notes (semiquaver).
func get_16th(p_time: float = Conductor.time, p_bpm: float = Conductor.bpm) -> float:
	return get_beat(p_time, p_bpm) * 0.25

## Snaps time to the nearest N-th note (e.g., 4 = quarter, 8 = eighth).
func snap_to_beat(p_time: float, p_bpm: float, subdiv: int = 4) -> float:
	return roundf(get_beat(p_time, p_bpm) * subdiv) / subdiv

## Converts Beats per minute to seconds.
func get_bps(p_bpm: float = Conductor.bpm) -> float:
	return 60.0 / p_bpm

## Returns the maximum amount of beats depending on the length given
func get_total_beats(p_length: float = Conductor.length, p_bpm: float = Conductor.bpm) -> float:
	return (p_bpm / 60.0) * p_length
#endregion
