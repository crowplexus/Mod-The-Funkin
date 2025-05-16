class_name NoteCollection extends Resource
# stole the idea from nebulazorua lol :3
# NOTE: this only exists for the chart editor.

@export var notes: Array[Array] = [
	[] as Array[NoteData], # Player 1 / Boyfriend
	[] as Array[NoteData], # Player 2 / Dad
]
var length: int = 0

## Adds a new player to the note collection[br]
## [b]Careful[/b], this clears any notes from a pre-existing player.
func add_player(at: int) -> void:
	if at < notes.size():
		notes[at].clear()
	else:
		notes.append([] as Array[NoteData])

## Adds a note to a player according to the [param]data[/param] passed.
func add_note(data: NoteData) -> void:
	if (data.side+1) > notes.size(): add_player(data.side)
	if length > notes[data.side].size(): length += 1
	notes[data.side].append(data)

func remove_note_at(player: int, index: int) -> void:
	notes[player].remove_at(index)

#region Note Grabbing Functions

## Gets all the notes from all players in the collection.
func get_all(sort: bool = false) -> Array[NoteData]:
	var collected: Array[NoteData] = []
	for player: Array in notes:
		for note: NoteData in player:
			collected.append(note)
	if sort: collected.sort_custom(NoteData.sort_by_time)
	return collected

## Gets all the notes from a specific player.
func get_sided(player: int) -> Array[NoteData]:
	return notes[player].duplicate()

## Gets all notes within a time range.
func get_in_time_range(start: float, end: float) -> Array[NoteData]:
	var result: Array[NoteData] = []
	for player_notes in notes:
		for note in player_notes:
			if start <= note.time and note.time <= end:
				result.append(note)
	return result

# TODO: ^ that, but with measures instead? maybe???

#endregion

#region Sorting Functions

## Sort every player (may take a while depending on the note count).
func sort_everything() -> void:
	for player: Array in notes: player.sort_custom(NoteData.sort_by_time)

## Sort one specific player.
func sort_player(side: int) -> void:
	if side < notes.size(): notes[side].sort_custom(NoteData.sort_by_time)

#endregion
