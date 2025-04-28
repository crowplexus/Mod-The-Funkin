class_name AlphabetMenu extends AnimatedLabel2D

signal item_created(item: Control)

@export var active: bool = true ## Updates all items.
@export var items: Array[String] = [] ## List of items to display.
@export var distance: Vector2 = Vector2(0, 80) ## Distance per each item.
@export var offset: Vector2 = Vector2.ZERO ## General offset of all items.
@export var change_x: bool = true ## Updates the X-axis of each item.
@export var change_y: bool = true ## Updates the Y-axis of each item.
var target_offset: int = 0 ## Selected item offset.
var position_lerp: float = 0.15 ## Lerp for all the items.

func _process(_delta: float) -> void:
	if not active:
		return
	for i: Control in get_children():
		update_item(i)

func update_item(item: Control,) -> void:
	var index: int = item.get_index() - target_offset
	var target_pos: Vector2 = Vector2.ZERO
	if change_x: target_pos.x = index * distance.x
	if change_y: target_pos.y = index * distance.y
	item.position = item.position.lerp(target_pos + offset, position_lerp)

func regen_list() -> void:
	for i: Node in get_children():
		remove_child(i)
		i.queue_free()
	if items.is_empty():
		push_warning("There's nothing…")
		return
	var final_text: String = ""
	for idx: int in items.size():
		final_text += items[idx]
		if idx < items.size() - 1:
			final_text += "\n"
	self.text = final_text.dedent()
	for line: Control in get_children():
		item_created.emit(line)

#region Array Functions

## Returns a random element from the array. Generates an error and returns null if the array is empty.
func pick_random() -> Control: return items.pick_random()
## Sorts the array using a custom [Callable].
func sort_custom(fun: Callable) -> void: items.sort_custom(fun)
## Returns the number of elements in the array. Empty arrays ([]) always return 0.
## See also [code]is_empty()[/code].
func array_size() -> int: return items.size()
## Returns true if the array is empty ([]).
## See also [code]size()[/code].
func is_empty() -> bool: return items.is_empty()
## Returns the first element of the array. If the array is empty, fails and returns null. See also back().[br]
## Note: Unlike with the [] operator (array[0]), an error is generated without stopping project execution.
func front() -> Control: return items.front()
## Returns the last element of the array. If the array is empty, fails and returns null. See also front().[br]
## Note: Unlike with the [] operator (array[-1]), an error is generated without stopping project execution.
func back() -> Control: return items.back()

#endregion
