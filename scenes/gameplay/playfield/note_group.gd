extends Node2D

signal on_note_spawned(data: NoteData, note: Note)
signal on_note_deleted(note: Note)

const TEMPLATE_NOTE: PackedScene = preload("res://scenes/gameplay/playfield/notes/normal_note.tscn")

@export var active: bool = true

var offset: float = 0.0
var note_list: Array[NoteData] = []
var list_position: int = 0
var speed: float = 1.0

func _ready() -> void:
	list_position = 0

func _process(_delta: float) -> void:
	if not active:
		return
	try_spawning()
	move_present_nodes()


func spawning_complete() -> bool:
	return note_list.size() == 0 or list_position >= note_list.size()


func move_present_nodes() -> void:
	for node: Node in get_children():
		if not node.visible:
			continue
		# NOTE: node is the note itself
		if node.moving: node.scroll_ahead()
		var miss_delay: float = 0.75 # default for botplay
		if node.note_field and node.note_field.player and node.note_field.player is Player:
			miss_delay = 0.3
		# preventing orphan nodes hopefully with this.
		if (not node.was_hit or node.die_later) and (Conductor.playhead - node.time) > miss_delay:
			if miss_delay == 0.3 and not node.was_hit:
				node.note_field.player.miss_note.emit(node, node.column)
				node.was_missed = true
			node.hide_all()
			on_note_deleted.emit(node)


func try_spawning() -> void:
	while list_position < note_list.size():
		var note_data: NoteData = note_list[list_position]
		if absf(note_data.time - Conductor.playhead + offset) > (1.25 / speed):
			break
		var new_note: Note = get_note()
		on_note_spawned.emit(note_data, new_note)
		if new_note.note_field:
			new_note.visible = new_note.note_field.visible
		new_note.reload(note_data)
		list_position += 1


func get_note() -> Node:
	#for node: Node in get_children():
	#	if not node.visible:
	#		return node
	var duped: = TEMPLATE_NOTE.instantiate()
	duped.name = "note%s" % list_position
	#duped.hide_all()
	add_child(duped)
	return duped
