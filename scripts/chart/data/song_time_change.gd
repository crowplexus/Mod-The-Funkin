# [TODO: docs]
class_name SongTimeChange extends Resource

@export var bpm: float = 100.0
@export var time: float = 0.0

static func make(_time: float = 0.0, _bpm: float = 100.0) -> SongTimeChange:
	var change: SongTimeChange = SongTimeChange.new()
	change.bpm = _bpm
	change.time = _time
	return change

func calculate_beat() -> float:
	return (time * bpm) / 60.0

func calculate_beat_delta(delta: float) -> float:
	return (bpm / 60.0) * delta

func calculate_crotchet() -> float:
	return 60.0 / bpm

static func sort_by_time(a: SongTimeChange, b: SongTimeChange) -> int:
	return a.time < b.time
