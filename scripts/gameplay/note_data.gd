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
@export var kind: StringName = DEFAULT_NOTE_KIND
## Note Length, spawns a tail in the note if specified.
@export var length: float = 0.0
## Animation Suffix for the note.
@export var anim_suffix: String = ""
## Custom Parameters.
@export var params: Dictionary = {}

#region Stepmania Functions

# all of this is mostly used for quants because I don't wanna make a like
# ALIEN ass looking beat-based quants or some bullshit like that
# the extra functions are there just in case I end up extending upon this system.

const ROWS_PER_BEAT: int = 48 ## Fixed-point time/beat representation from SM.
const ROWS_PER_MEASURE: int = ROWS_PER_BEAT * 4 ## Rows used in a measure
const QUANT_LIST: Array[int] = [4, 8, 12, 16, 24, 32, 48, 64, 192] ## List of quant types.

const QUANT_COLOR_PRESETS: Dictionary[String, PackedColorArray] = {
	"default": [
		Color("#ff3333"), Color("#3388ff"), Color("#33ff55"), # 4th, 8th, 12th
		Color("#cc33ff"), Color("#ffee33"), Color("#aa33ff"), # 16th, 24th, 32nd
		Color("#ff33aa"), Color("#ff9933"), Color("#888888"), # 48th, 64th, 192nd
	],
	"kadeish": [
		Color("#f9393f"), Color("#00ffff"), Color("#12fa05"), # 4th, 8th, 12th
		Color("#c24b99"), Color("#ffd700"), Color("#ff7f00"), # 16th, 24th, 32nd
		Color("#ff00ff"), Color("#00ff7f"), Color("#7f00ff"), # 48th, 64th, 192nd
	]
}
const QUANT_COLORS: PackedColorArray = QUANT_COLOR_PRESETS.kadeish

## Retrieve a quantized note row for the note.
static func get_note_quant(row: int) -> int:
	for quant: int in QUANT_LIST:
		if row % (ROWS_PER_MEASURE / quant) == 0:
			return quant
	return QUANT_LIST[-1]

# temporary until the options menu gets remade
static func get_quant_color(row: int) -> Color:
	match row:
		4: return QUANT_COLORS[0]
		8: return QUANT_COLORS[1]
		12:return QUANT_COLORS[2]
		16:return QUANT_COLORS[3]
		24:return QUANT_COLORS[4]
		32:return QUANT_COLORS[5]
		48:return QUANT_COLORS[6]
		64:return QUANT_COLORS[7]
		_: return QUANT_COLORS[8]

# needless to say, ikepotchey, chihuisepapa
# never dales, conecosna heibi amare
# TODO: adjust these to time signature.

## Converts time to a note row.
static func secs_to_row(p_time: float, p_bpm: float = Conductor.bpm) -> int:
	return round(Conductor.get_beat(p_time, p_bpm) * ROWS_PER_BEAT)

## Converts a beat value to a note row.
static func beat_to_row(p_beat: float) -> int:
	return round(p_beat * ROWS_PER_BEAT)

## [code]NoteData.beat_to_row[/code] but in reverse.
static func row_to_beat(p_row: int) -> float:
	return p_row / ROWS_PER_BEAT

## [code]NoteData.secs_to_row[/code] but in reverse.
static func row_to_secs(p_row: int, p_bpm: float = Conductor.bpm) -> float:
	return Conductor.get_time(p_row / ROWS_PER_BEAT, p_bpm)

## Snaps a row to the nearest quant.
static func snap_row_to_quant(row: int, quant: int) -> int:
	assert(quant in QUANT_LIST, "Invalid quant value!")
	return roundi(float(row) / quant) * quant

#endregion

func _to_string() -> String:
	return "[%s, %s, %s, %s]" % [ time, column, kind, length ]

#region Note Generation Functions

const DEFAULT_NOTE_KIND: StringName = &"_"

## Schema must use the original FNF format, that being:[br][br]
## [ time: float (ms), column: int, length: float (ms), data: String ]
static func from_array(data: Array, max_columns: int = 4, return_raw_column: bool = false) -> NoteData:
	var swag_note: NoteData = NoteData.new()
	var raw_column: int = int(data[1])
	swag_note.time = float(data[0]) * 0.001
	if data.size() > 3 and not str(data[3]).is_empty():
		swag_note.kind = StringName(str(data[3]))
		match swag_note.kind:
			&"Hurt Note": swag_note.kind = &"mine" # psych.
			_: swag_note.kind = DEFAULT_NOTE_KIND
		if swag_note.kind != DEFAULT_NOTE_KIND and not swag_note.kind in Gameplay.NOTE_TYPES:
			swag_note.kind = DEFAULT_NOTE_KIND # default
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
		if "p" in dictionary: new_note.params = Dictionary(dictionary.p)
		if "k" in dictionary: new_note.kind = StringName(dictionary.k)
		new_note.side = int(new_note.column / max_columns)
	return new_note

static func sort_by_time(one: NoteData, two: NoteData) -> int:
	return one.time < two.time

#endregion
