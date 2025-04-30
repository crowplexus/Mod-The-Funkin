## Resource for constructing a song item[br]
## Mostly used in freeplay.
class_name SongItem extends Resource

## Name shown in the menu.
@export var name: StringName = &"Unknown" ## Folder used to locate the song (for loading charts from).
@export var folder: String = "test" ## Song Difficulties, used in Freeplay.
@export var difficulties: PackedStringArray = ["easy", Global.DEFAULT_DIFFICULTY, "hard"] ## List to display this song in, used in Freeplay.
@export var show_in_campaign: bool = true ## Toggles display the song in Campaign Mode.
@export var shown_in_freeplay: bool = true ## Toggle displaying the song in Freeplay.
