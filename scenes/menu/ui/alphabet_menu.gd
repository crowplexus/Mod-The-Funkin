class_name AlphabetMenu extends Control

const ALPHABET_LABEL_SETTINGS: LabelSettings = preload("res://assets/ui/fonts/alphabet_font_bold.tres")

signal item_created(item: Control)

@export var active: bool = true ## Updates all items.
@export var items: Array[String] = [] ## List of items to display.
@export var distance: Vector2 = Vector2(0, 80) ## Distance per each item.
@export var offset: Vector2 = Vector2.ZERO ## General offset of all items.
@export var change_x: bool = true ## Updates the X-axis of each item.
@export var change_y: bool = true ## Updates the Y-axis of each item.
var start_positions: Array[Vector2] = [] ## List of positions the items start at.
var scroll_lerp: float = 0.15 ## Value used for lerp weight.
var scroll_offset: int = 0: ## Menu scroll offset.
	get: return clamp(scroll_offset, 0, items.size()) # just making sure.

func _process(_delta: float) -> void:
	if not active:
		return
	for i: Control in get_children():
		scroll_item(i)

func scroll_item(item: Control) -> void:
	if not change_x and not change_y:
		return
	var index: int = item.get_index()
	var pos: Vector2 = start_positions[index] + offset
	var selected: int = (index - scroll_offset)
	#var fscale: Vector2 = item.scale * scale
	var height: float = (item as Label).get_line_height()
	item.position = item.position.lerp(Vector2(
		pos.x + (selected * distance.x) * int(change_x),
		pos.y + (selected * (height + distance.y)) * int(change_y)),
	scroll_lerp)

func regen_list() -> void:
	for i: Node in get_children():
		remove_child(i)
		i.queue_free()
	if items.is_empty():
		push_warning("There's nothing…")
		return
	for idx: int in items.size():
		var text_entry: Label = Label.new()
		text_entry.label_settings = ALPHABET_LABEL_SETTINGS.duplicate()
		text_entry.text = items[idx].to_upper()
		add_child(text_entry)
	# children are generated after setting the text
	# each "line" is an entry on the menu, hence why we just set the text before.
	for line: Control in get_children():
		item_created.emit(line)
		start_positions.append(line.position)

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
