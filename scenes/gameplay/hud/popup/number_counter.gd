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
	var offset: float = strv.size() - 3
	for i: int in strv.size():
		if i > _len - 1:
			add_child(zeroth.duplicate())
		var num: Sprite2D = get_child(i)
		if strv[i] == "-":
			num.frame = 0
		else:
			num.frame = int(strv[i]) + 1
		var w: int = num.texture.get_width()
		num.position.x = (((w - size.x) * 0.1) + (45 * i)) - (scale.x * offset)

func clear_numbers() -> void:
	for i: CanvasItem in get_children():
		if not i is Sprite2D: continue
		i.visible = i.get_index() <= str(value).pad_zeros(minimum_digits).length()
		i.frame = 1
