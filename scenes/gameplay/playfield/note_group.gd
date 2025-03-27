extends Node2D

const TEMPLATE_NOTE: PackedScene = preload("res://scenes/gameplay/playfield/notes/normal_note.tscn")

signal on_note_spawned(data: NoteData, note: Note)
signal on_note_deleted(note: Note)

@export var active: bool = true

var note_list: Array[NoteData] = []
var list_position: int = 0

func _ready() -> void:
	list_position = 0
	#for i: int in 64: # precache this many notes
	#	var preload_note: = TEMPLATE_NOTE.instantiate()
	#	preload_note.name = "preload%s" % str(i)
	#	preload_note.top_level = true
	#	preload_note.hide_all()
	#	add_child(preload_note)


func _process(_delta: float) -> void:
	if not active:
		return
	try_spawning()
	move_present_nodes()


func spawning_complete() -> bool:
	return note_list.size() == 0 or list_position >= note_list.size()


func move_present_nodes() -> void:
	for i: int in get_child_count():
		var node: Note = get_child(i)
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
		if absf(note_data.time - Conductor.time) > 1.0: # TODO: account for note speed
			break
		var new_note: Note = get_note()
		on_note_spawned.emit(note_data, new_note)
		if new_note.note_field: # TODO: move note group to note field
			new_note.visible = new_note.note_field.visible
		new_note.reload(note_data)
		list_position += 1#= clampi(list_position + 1, 0, note_list.size())
		#print_debug("spawned at ", Conductor.time)


func get_note() -> Node:
	#for node: Node in get_children():
	#	if not node.visible:
	#		return node
	var duped: = TEMPLATE_NOTE.instantiate()
	duped.name = "note%s" % list_position
	#duped.hide_all()
	add_child(duped)
	return duped
