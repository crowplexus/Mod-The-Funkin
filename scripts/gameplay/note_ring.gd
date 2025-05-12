# literally there's no reason for me to be doing this???
# notes spawn fast enough, it isn't that expensive, but...
# i hate myself!
class_name NoteRing

signal spawned_note(data: NoteData)

const SPAWN_SECS: float = 0.9 # 900ms
var reverse: bool = false
var notes: Array[NoteData]
var cursor: int = 0
var length: int = 0

func _init(notes: Array[NoteData]) -> void:
	self.notes = notes
	self.length = notes.size()

func reverse_modifier() -> void:
	reverse = true
	cursor = length-1

func spawn(note_spawn_callback: Callable) -> void:
	if not note_spawn_callback:
		push_error("Cannot spawn notes without a callback.")
		return
	var play_time: float = Conductor.playhead
	while true: # oooo scary infinite loop.
		var note: NoteData = peek()
		if absf(note.time - play_time) > SPAWN_SECS:
			break
		if notes.is_empty(): # in case notes gets cleared.
			break
		note_spawn_callback.call(note)
		spawned_note.emit(note)
		next()

## Returns the current note.
func peek() -> NoteData:
	return notes[cursor]

## Gets the next note and advances the cursor.
func next() -> NoteData:
	cursor = (cursor + 1) % length
	return notes[cursor]

## Goes back one note and rewinds the cursor.
func previous() -> NoteData:
	cursor = (cursor - 1) % length
	return notes[cursor]

func earliest_time() -> float:
	return notes[0].time if not notes.is_empty() else 0.0

func latest_time() -> float:
	return notes[-1].time if not notes.is_empty() else 0.0

func seek(time: float) -> int:
	#cursor = notes.bsearch(Conductor.time) # ok.
	var lowest: int = 0
	var highest: int = length - 1
	while lowest <= highest: # is this what the people call binary search?
		var middle: int = (lowest + highest) >> 1 # oh i see why its called binary search.
		if notes[middle].time < time:
			lowest = middle + 1
		else:
			highest = middle - 1
	cursor = clampi(lowest, 0, length - 1)
	return cursor
