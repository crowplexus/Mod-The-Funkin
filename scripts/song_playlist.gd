## Resource for a list of songs.[br]
## Used mainly in Menus.
class_name SongPlaylist extends Resource

@export var list: Array[SongItem] = [] ## List of songs to load.
@export var tagline: StringName = "Unknown" ## Tagline shown in Story Mode.
## Difficulties specifically in Story Mode.[br]
## make sure all of the songs have the difficulties specified here.
@export var campaign_difficulties: Array[String] = ["easy", Global.DEFAULT_DIFFICULTY, "hard"]
@export var title_texture: Texture2D ## Level Title Texture (for Story Mode visuals).
## What kind of visibility does this level have?[br]
## Each of these values are sort of self-explanatory either way.
@export_enum("Visible:0", "Hidden:1", "Hidden in Story:2", "Hidden in Freeplay:3")
var visible: int = 0
## What kind of lock does this level have?[br]
## Unlocked = 0 -- None.[br]Locked = 1 -- Locked Everywhere.[br]
## Freeplay = Locked until beaten in Story Mode.
@export_enum("Unlocked:0", "Locked:1", "Freeplay:2")
var lock_type: int = 0
@export var level_color: Color = Color(0.976, 0.812, 0.318) ## Color for when selecting in the Story Menu.

## Returns a random element from the array. Generates an error and returns null if the array is empty.
func pick_random() -> SongItem: return list.pick_random()
## Sorts the array using a custom [Callable].
func sort_custom(fun: Callable) -> void: list.sort_custom(fun)
## Returns the number of elements in the array. Empty arrays ([]) always return 0.
## See also [code]is_empty()[/code].
func size() -> int: return list.size()
## Returns true if the array is empty ([]).
## See also [code]size()[/code].
func is_empty() -> bool: return list.is_empty()
## Returns the first element of the array. If the array is empty, fails and returns null. See also back().[br]
## Note: Unlike with the [] operator (array[0]), an error is generated without stopping project execution.
func front() -> SongItem: return list.front()
## Returns the last element of the array. If the array is empty, fails and returns null. See also front().[br]
## Note: Unlike with the [] operator (array[-1]), an error is generated without stopping project execution.
func back() -> SongItem: return list.back()
