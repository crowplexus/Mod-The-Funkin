@tool extends Control

@onready var label: Label = $"label"
@export var song: SongItem
@export var text: String:
	set(new_text):
		if label: label.text = new_text
		text = new_text
