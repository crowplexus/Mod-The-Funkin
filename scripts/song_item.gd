## Resource for constructing a song item[br]
## Mostly used in freeplay.
class_name SongItem extends Resource

## Name shown in the menu.
@export var name: StringName = &"Unknown" ## Folder used to locate the song (for loading charts from).
@export var folder: String = "test" ## Song Difficulties, used in Freeplay.
@export var difficulties: PackedStringArray = ["easy", Global.DEFAULT_DIFFICULTY, "hard"] ## List to display this song in, used in Freeplay.
## Defines how should the song be displayed.[br]
## Visible: 0 -- Always | Hidden: 1 -- Never[br]
## Locked: 2 -- When beaten in Story Mode.[br]The other 2 are self-explanatory.
@export_enum("Visible:0", "Hidden:1", "Locked:2", "Hidden in Story:3", "Hidden in Freeplay:4")
var visible: int = 0
