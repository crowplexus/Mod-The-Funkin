## Resource for a list of songs.[br]
## Used mainly in freeplay.
class_name SongPlaylist extends Resource

@export var list: Array[SongItem] = [] ## List of songs to load.
@export var tagline: StringName = "Unknown" ## Tagline shown in Campaign Mode.
## Difficulties specifically in Campaign Mode.[br]
## make sure all of the songs have the difficulties specified here.
@export var campaign_difficulties: Array[String] = ["easy", Global.DEFAULT_DIFFICULTY, "hard"]
@export var show_in_campaign: bool = true ## Toggles if this playlist is able to be shown in Campaign Mode.
@export var show_in_freeplay: bool = true ## Toggles if this playlist is able to be shown in Freeplay Mode.

## Returns a random element from the array. Genertates an error and returns null if the array is empty.
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
