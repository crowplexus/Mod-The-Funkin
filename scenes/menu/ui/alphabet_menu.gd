@tool extends Control

signal item_created(item: AnimatedLabel2D)

@export var sprite_frames: SpriteFrames = preload("res://assets/ui/fonts/alphabet.res")

@export var active: bool = true ## Updates all items.
@export var items: Array[String] = [] ## List of items to display.
@export var distance: Vector2 = Vector2(0, 80) ## Distance per each item.
@export var offset: Vector2 = Vector2.ZERO ## General offset of all items.
@export var change_x: bool = true ## Updates the X-axis of each item.
@export var change_y: bool = true ## Updates the Y-axis of each item.
@export var position_lerp: float = 0.15 ## Lerp for all the items.
@export var reload: bool = false: ## Debug button for the editor, reloads the list.
	set(rl):
		regen_list()
		reload = false
var target_offset: int = 0
var initial_pos: Array[Vector2] = []

func _process(_delta: float) -> void:
	if active:
		for i: Control in get_children():
			update_item(i)

func update_item(item: Control,) -> void:
	var index: int = item.get_index()
	var target_pos: Vector2 = Vector2.ZERO
	if change_x: target_pos.x = (index - target_offset) * distance.x
	if change_y: target_pos.y = (index - target_offset) * distance.y
	item.position = item.position.lerp(target_pos + offset, position_lerp)

func regen_list() -> void:
	for i: Node in get_children():
		remove_child(i)
		i.queue_free()
	if items.is_empty():
		push_warning("There's nothing…")
		return
	for idx: int in items.size():
		var new_item: AnimatedLabel2D = AnimatedLabel2D.new()
		new_item.name = items[idx].to_snake_case()
		new_item.sprite_frames = sprite_frames
		new_item.position = Vector2(idx * distance.x, idx * distance.y)
		new_item.variant = AnimatedLabel2D.CharacterType.BOLD
		new_item.text = items[idx]
		initial_pos.append(new_item.position)
		item_created.emit(new_item)
		add_child(new_item)

#region Array Functions

## Returns a random element from the array. Generates an error and returns null if the array is empty.
func pick_random() -> Control: return items.pick_random()
## Sorts the array using a custom [Callable].
func sort_custom(fun: Callable) -> void: items.sort_custom(fun)
## Returns the number of elements in the array. Empty arrays ([]) always return 0.
## See also [code]is_empty()[/code].
func size() -> int: return items.size()
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
