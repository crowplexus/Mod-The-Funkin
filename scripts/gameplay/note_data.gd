## Raw Note Data, used for loading charts.
class_name NoteData extends Resource

## Empty note data with all of its values set to the defaults.
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

#region Stepmania Functions

# all of this is mostly used for quants because I don't wanna make a like
# ALIEN ass looking beat-based quants or some bullshit like that
# the extra functions are there just in case I end up extending upon this system.

const ROWS_PER_BEAT: int = 48 ## Fixed-point time/beat representation from SM.
const ROWS_PER_MEASURE: int = ROWS_PER_BEAT * 4 ## Rows used in a measure
const QUANT_LIST: Array[int] = [4, 8, 12, 16, 24, 32, 48, 64, 192] ## List of quant types.

## Convert the beat into a note row.
static func beat_to_note_row(f_beat: float) -> int:
	return roundi(f_beat * ROWS_PER_BEAT)

## Convert the note row to a beat.
static func note_row_to_beat(i_row: int) -> float:
	return float(i_row) / ROWS_PER_BEAT

## Retrieve the proper quantized NoteType for the note.
static func get_note_quant(row: int) -> int:
	for quant: int in QUANT_LIST:
		if row % (ROWS_PER_MEASURE % quant) == 0:
			return quant
	return QUANT_LIST[-1]

## Snaps a row to the nearest quant.
static func snap_row_to_quant(row: int, quant: int) -> int:
	assert(quant in QUANT_LIST, "Invalid quant value!")
	return roundi(float(row) / quant) * quant

#endregion

func _to_string() -> String:
	return "[%s, %s, %s, %s]" % [ time, column, kind, length ]

#region Note Generation Functions

## Schema must use the original FNF format, that being:[br][br]
## [ time: float (ms), column: int, length: float (ms), data: String ]
static func from_array(data: Array, max_columns: int = 4, return_raw_column: bool = false) -> NoteData:
	var swag_note: NoteData = NoteData.new()
	var raw_column: int = int(data[1])
	swag_note.time = float(data[0]) * 0.001
	if data.size() > 3 and data[3] != "":
		swag_note.kind = StringName(data[3])
	swag_note.length = float(data[2]) * 0.001
	if not return_raw_column:
		swag_note.column = raw_column % max_columns
	else:
		swag_note.column = raw_column
	swag_note.side = int(swag_note.column / max_columns)
	return swag_note

## Schema must use the VSlice format, that being:[br][br]
## [code]{ "t": float, "d": int, "l": float, "k": StringName, "p": Array[Variant] }[/code]
static func from_dictionary(dictionary: Dictionary, max_columns: int = 4) -> NoteData:
	var new_note: NoteData = NoteData.new()
	new_note.column = -1
	if "t" in dictionary and "d" in dictionary: # can spawn
		new_note.time = float(dictionary.t * 0.001)
		new_note.column = int(dictionary.d)
		if "l" in dictionary: new_note.length = float(dictionary.l * 0.001)
		if "k" in dictionary: new_note.kind = StringName(dictionary.k)
		if "p" in dictionary: new_note.params = Array(dictionary.p)
		new_note.side = int(new_note.column / max_columns)
	return new_note

static func sort_by_time(one: NoteData, two: NoteData) -> int:
	return one.time < two.time

#endregion
