## Node to create new note types from a basic object.[br]
## You can decide how it looks, how it loads, etc.[br][br]
## Scene Tree must look like this:[br][br]
## arrow (Any Node2D type)[br]
## clip_rect (Any Control Type)[br]
##		hold_body (TextureRect)[br]
##		hold_tail (TextureRect)[br]
class_name Note extends Node2D

## Default Directions. TODO: replace this
const COLORS: PackedStringArray = ["purple", "blue", "green", "red"]
## Default Note Distance (in pixels).
const DISTANCE: float = 450.0
## Arrow Size (in pixels), for test purposes.
const ARROW_SIZE: float = 64.0
## Hardcoded Speed Multiplier for new movement math.
const SPEED_MULT: float = 8.0

static func get_scroll_as_vector(scroll: int) -> Vector2:
	match scroll:
		1: return Vector2(-1, 1) # Down
		_: return -Vector2.ONE # Up (default)
## This is for the notefield that the note is targetting.
var note_field: NoteField
## Data used mainly for hold sizes and whatnot.
var data: NoteData:
	set(new_data):
		time = new_data.time
		column = new_data.column
		length = new_data.length
		kind = new_data.kind
		side = new_data.side
## (Current) Hold Size, not to be confused with [code]data.length[/code]
var hold_size: float = 0.0
## Hold note body, gets attached if [code]$"clip_rect/hold_body"[/code]
## exists in the scene tree.
var hold_body: TextureRect
## Hold note tail, gets attached if [code]$"clip_rect/hold_tail"[/code]
## exists in the scene tree.
var hold_tail: TextureRect
## Control Node for hiding offscreen hold notes.
var clip_rect: Control

## Note Spawn Time (in seconds).
var time: float = -1.0
## Note Column/Direction.
var column: int = -1
## Note Player ID/Side.[br]0 = Enemy, 1 = Player, etc...
var side: int = -1
## Note Type/Kind, if unspecified or non-existant,
## The default note type will be used instead.
var kind: StringName
## Note Length, spawns a tail in the note if specified.
var length: float = -1.0

# Input stuff
var was_hit: bool = false
var was_missed: bool = false
var die_later: bool = false
#var late_hitbox: float = 1.0
#var early_hitbox: float = 1.0
var hit_time: float = 0.0
var judgement: Judgement
# FOR HOLDS
var dropped: bool = false
var trip_timer: float = 1.0
var _stupid_visual_bug: bool = false
# VISUALS
var scroll_mult: Vector2 = -Vector2.ONE
var moving: bool = true

func hide_all() -> void: queue_free()
func show_all() -> void: show()

## Override this to allow the note to have a note splash.
func can_splash() -> bool:
	return false

var _old_sm: Vector2 = Vector2.ZERO

func _ready() -> void:
	if has_node("clip_rect"):
		clip_rect = get_node("clip_rect")
		if has_node("clip_rect/hold_body"): hold_body = get_node("clip_rect/hold_body")
		if has_node("clip_rect/hold_tail"): hold_tail = get_node("clip_rect/hold_tail")
	reset_scroll()

func reset_scroll() -> void:
	var game: Gameplay = Gameplay.current
	scroll_mult = Note.get_scroll_as_vector(game.local_settings.scroll if game else Global.settings.scroll)
	if clip_rect and scroll_mult != _old_sm:
		clip_rect.scale *= -scroll_mult
	_old_sm = scroll_mult

func get_total_speed() -> float:
	var speed: float = note_field.speed * note_field.get_receptor(column).speed
	return speed * Note.SPEED_MULT

func scroll_ahead() -> void:
	if not note_field or column == -1:
		return
	# i stole this shit from OpenITG https://github.com/openitg/openitg/blob/f2c129fe65c65e4a9b3a691ff35e7717b4e8de51/src/ArrowEffects.cpp#L42
	# TODO: change how speed works later
	var beat_speed: float = get_total_speed()#Conductor.bpm
	var secs_until_step: float = time - Conductor.playhead
	var next_y: float = secs_until_step * beat_speed * Note.ARROW_SIZE
	position.y = note_field.global_position.y + next_y * -scroll_mult.y #/ absf(scale.y)

func update_hold(_delta: float) -> void:
	moving = false
	position.y = note_field.global_position.y
	if _stupid_visual_bug:
		hold_size += hit_time / absf(clip_rect.scale.y)
		_stupid_visual_bug = false
	hold_size = (time + length) - Conductor.playhead
	display_hold(hold_size, get_total_speed())
	if (hold_size <= 0.0 or trip_timer <= 0.0) and not die_later:
		hide_all()

## Override this function to do something when you finish holding all the way through.
func hold_finished() -> void:
	pass

## Use this function to initialise the note itself and related properties[br]
## Called whenever a note is spawned, remember to also call super(data)
func reload(p_data: NoteData) -> void:
	data = p_data
	hold_size = p_data.length
	_stupid_visual_bug = false
	was_missed = false
	was_hit = false
	moving = true

## Use this function for implementing hold note visuals.[br]
## Leave empty if you want your note type to not have holds.
func display_hold(size: float = 0.0, speed: float = -1.0) -> void:
	if speed <= 0.0: speed = get_total_speed()
	if column != -1 and not hold_body or not clip_rect:
		return
	# general implementation, should work for everything???
	hold_body.size.x = hold_body.texture.get_width()
	hold_body.size.y = (size * (speed * 100.0)) - 0.01

## Use this function for implementing splash visuals.[br]
## Return null if you don't want note splashes on your note type.
func display_splash() -> Node2D:
	return null

## Checks if the note is in range to be hitp
func is_hittable(hit_window: float = 0.18) -> bool:
	#const diff: float = data.time - Conductor.playhead
	#return absf(diff) <= (hit_window * (early_hitbox if diff < 0 else late_hitbox))
	return absf(Conductor.playhead - time) <= hit_window and not was_hit and not was_missed
