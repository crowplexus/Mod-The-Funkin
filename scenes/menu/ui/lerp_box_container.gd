class_name LerpBoxContainer extends Control

@export var move_x: bool = true ## Makes the list move in the X axis.
@export var move_y: bool = true ## Makes the list move in the Y axis.

@export var position_lerp: Vector2 = Vector2(0.15, 0.15) ## Lerp for all the items.
@export var list_offset: Vector2 = Vector2.ZERO ## (Absolute) offset for each item.
@export var spacing: Vector2 = Vector2(50, 50) ## Spacing between each item.

func _process(_delta: float) -> void:
	for item: Control in get_children():
		if move_x: item.position.x = lerpf(item.position.x, list_offset.x + (item.get_index() * spacing.x), position_lerp.x)
		if move_y: item.position.y = lerpf(item.position.y, list_offset.y + (item.get_index() * spacing.y), position_lerp.y)
