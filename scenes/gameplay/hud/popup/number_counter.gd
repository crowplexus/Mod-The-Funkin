extends Control

@export var minimum_digits: int = 3 ## How many digits to display at minimum.
@export var value: int = 0: ## Value to display.
	set(new_value):
		value = new_value
		update_counter()
@onready var zeroth: Sprite2D = $"digit0"

func update_counter() -> void:
	clear_numbers()
	var strv: PackedStringArray = str(value).pad_zeros(minimum_digits).split("")
	var _len: int = get_child_count()
	for i: int in strv.size():
		if i > _len - 1:
			add_child(zeroth.duplicate())
		var num: Sprite2D = get_child(i)
		if strv[i] == "-":
			num.frame = 0
		else:
			num.frame = int(strv[i]) + 1
		num.position.x = (40 * i)

func clear_numbers() -> void:
	for i: CanvasItem in get_children():
		i.visible = i.get_index() <= str(value).pad_zeros(minimum_digits).length()
		i.frame = 1
