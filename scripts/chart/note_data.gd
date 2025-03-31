## Raw Note Data, used for loading charts.
class_name NoteData
extends Resource

static var EMPTY: NoteData = NoteData.new():
	set(new):
		if EMPTY == null:
			EMPTY = new

## Note Spawn Time (in seconds).
@export var time: float = 0.0
## Note Column/Direction.
@export var column: int = 0
## Note Player ID/Side.[br]0 = Enemy, 1 = Player, etc...
@export var side: int = 0
## Note Type/Kind, if unspecified or non-existant,
## The default note type will be used instead.
@export var kind: StringName = &"default"
## Note Length, spawns a tail in the note if specified.
@export var length: float = 0.0
## Custom Parameters.
@export var params: Array = []

func _to_string() -> String:
	return "[%s, %s, %s, %s]" % [ time, column, kind, length ]

## Schema must use the original FNF format, that being:[br][br]
## [ time: float (ms), column: int, length: float (ms), data: String ]
static func from_array(data: Array, max_columns: int = 4, return_raw_column: bool = false) -> NoteData:
	var swag_note: NoteData = NoteData.new()
	var raw_column: int = int(data[1])
	swag_note.time = float(data[0]) * 0.001
	swag_note.side = 0 if raw_column > (max_columns - 1) else 1
	#print_debug(swag_note.side)
	if data.size() > 3 and data[3] != "":
		swag_note.kind = StringName(data[3])
	swag_note.length = float(data[2]) * 0.001
	if not return_raw_column:
		swag_note.column = raw_column % max_columns
	else:
		swag_note.column = raw_column
	return swag_note

## Schema must use the VSlice format, that being:[br][br]
## [code]{ "t": float, "d": int, "l": float, "k": StringName, "p": Array[Variant] }[/code]
static func from_dictionary(dictionary: Dictionary) -> NoteData:
	var new_note: NoteData = NoteData.new()
	new_note.column = -1
	if "t" in dictionary and "d" in dictionary: # can spawn
		new_note.time = float(dictionary.t * 0.001)
		new_note.column = int(dictionary.d)
		if "l" in dictionary: new_note.length = float(dictionary.l * 0.001)
		if "k" in dictionary: new_note.kind = StringName(dictionary.k)
		if "p" in dictionary: new_note.params = Array(dictionary.p)
	return new_note


static func sort_by_time(one: NoteData, two: NoteData) -> int:
	return one.time < two.time
