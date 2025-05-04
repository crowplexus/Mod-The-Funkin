extends Control

@onready var info: Label = $"label"
@onready var default_text: String = info.text

func _ready() -> void:
	if info: info.text = str(get_index()+1) + " | " + default_text
