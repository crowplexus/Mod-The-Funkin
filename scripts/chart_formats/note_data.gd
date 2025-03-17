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


func _to_string() -> String:
	return "[%s, %s, %s, %s]" % [ time, column, kind, length ]


static func from_array(data: Array, max_columns: int = 4) -> NoteData:
	var swag_note: NoteData = NoteData.new()
	var raw_column: int = int(data[1])
	swag_note.time = float(data[0]) * 0.001
	swag_note.side = 0 if raw_column > (max_columns - 1) else 1
	#print_debug(swag_note.side)
	if data.size() > 3 and data[3] != "":
		swag_note.kind = &"%s" % data[3]
	swag_note.length = float(data[2]) * 0.001
	swag_note.column = raw_column % max_columns
	return swag_note
