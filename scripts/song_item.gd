## Resource for constructing a song item[br]
## Mostly used in freeplay.
class_name SongItem
extends Resource

## Name shown in the menu.
@export var name: StringName = &"Unknown"
## Folder used to locate the song (for loading charts from)
@export var folder: String = "test"
## Song Difficulties, used in freeplay.
@export var difficulties: PackedStringArray = ["easy", Global.DEFAULT_DIFFICULTY, "hard"]
## List to display this song in (for freeplay).
@export var list_name: StringName = &""
