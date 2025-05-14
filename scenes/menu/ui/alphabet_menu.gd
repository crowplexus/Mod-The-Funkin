class_name AlphabetMenu extends Control

const ALPHABET_LABEL_SETTINGS: LabelSettings = preload("res://assets/ui/fonts/alphabet_font_bold.tres")

signal item_created(item: Control)
signal list_regenerated()

@export var active: bool = true ## Updates all items.
@export var items: Array[String] = [] ## List of items to display.
@export var distance: Vector2 = Vector2(0, 60) ## Distance per each item.
@export var offset: Vector2 = Vector2.ZERO ## General offset of all items.
@export var change_x: bool = true ## Updates the X-axis of each item.
@export var change_y: bool = true ## Updates the Y-axis of each item.
@export var force_uppercase: bool = true ## All the text in the items will be uppercase.
@export var horizontal_alignment: = HORIZONTAL_ALIGNMENT_LEFT ## Horizontal alignment for each of the items.
@export var vertical_alignment: = VERTICAL_ALIGNMENT_TOP ## Vertical alignment for each of the items.
@export var items_change_alpha: bool = true ## If the items automatically change alpha when unselected/selected.
@export var scroll_speed: float = 1.5 ## Speed of the items when scrolling.
@export var visible_item_count: int = 5 ## How many items can be visible at a time.

var scroll_lerp: float = 0.15 ## Value used for lerp weight.
var start_positions: Array[Vector2] = [] ## List of positions the items start at.
var min_scroll_offset: int = 0 ## In case you have negative items??? how??? why???
var scroll_offset: float = 0.0 ## Menu scroll offset.
var focused_item_index: int = 0 ## Tracks which item should be highlighted on-screen.

func _process(delta: float) -> void:
	if not active or start_positions.is_empty():
		return
	var target_offset: float = clampf(focused_item_index - (visible_item_count-1)/2, 0, max(0, items.size() - visible_item_count))
	scroll_offset = lerpf(scroll_offset, target_offset, scroll_lerp * scroll_speed * delta * 60)
	for i: Control in get_children():
		scroll_item(i)

func scroll_item(item: Control) -> void:
	if not change_x and not change_y:
		return
	
	var index: int = item.get_index()
	var relative: float = index - scroll_offset
	var pos: Vector2 = start_positions[index] + offset
	var spacing: float = (item.label_settings.font.get_height() + item.label_settings.line_spacing) + distance.y
	
	var target_x: float = pos.x + (relative * distance.x) * int(change_x)
	#var target_y: float = pos.y + ((relative - (visible_item_count-1)/2) * spacing) * int(change_y)
	
	# this is painful.
	var center_offset: float = (size.y/2) - (spacing/2)
	var target_y: float = pos.y - scroll_offset * spacing + center_offset
	
	var visible_padding: float = spacing
	var bottom: float = size.y + visible_padding
	var top: float = -visible_padding
	
	item.visible = target_y >= top and target_y <= bottom
	if item.visible:
		item.position = item.position.lerp(Vector2(target_x, target_y), scroll_lerp * scroll_speed)
		if items_change_alpha: item.modulate.a = 0.6 if (index - focused_item_index) != 0 else 1.0

func regen_list() -> void:
	start_positions.clear()
	for child: Control in get_children():
		remove_child(child)
		child.queue_free()
		
	if items.is_empty():
		push_warning("There's nothing…")
		return
		
	var test_label: Label = Label.new()
	test_label.label_settings = ALPHABET_LABEL_SETTINGS
	var line_height: float = test_label.label_settings.font.get_height()
	var spacing: float = line_height + distance.y
	test_label.queue_free()
	
	for idx: int in items.size():
		var text_entry := Label.new()
		text_entry.name = items[idx].to_snake_case()
		text_entry.text = items[idx]
		text_entry.uppercase = force_uppercase
		text_entry.label_settings = ALPHABET_LABEL_SETTINGS.duplicate()
		text_entry.horizontal_alignment = horizontal_alignment
		text_entry.vertical_alignment = vertical_alignment
		text_entry.size = self.size
		await get_tree().process_frame
		text_entry.position = Vector2(0.0, (size.y/2) + (idx - (items.size()/2)) * spacing - (spacing/2))
		add_child(text_entry)
		start_positions.append(text_entry.position)
		item_created.emit(text_entry)
	
	list_regenerated.emit()

func focus_item(index: int) -> void:
	focused_item_index = index

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
