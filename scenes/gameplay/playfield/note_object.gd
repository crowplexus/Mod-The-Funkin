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
# for Stepmania movement math.
const SM_ARROW_SIZE: float = 80.0 # 64.0 originally.
const SM_SPEED_MULT: float = 10.0 # adjust for fnf notes.
const USE_SM_SCROLL: bool = true

## Strumline that this note is moving towards.
var strumline: Strumline
## Data used mainly for hold sizes and whatnot.
var data: NoteData:
	set(new_data):
		var offset: float = 0.0
		if Global.settings: offset = Global.settings.note_offset
		time = new_data.time + offset
		raw_time = new_data.time
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

var time: float = -1.0 ## Note Spawn Time (in seconds) with offset.
var raw_time: float = -1.0 ## Raw Note Spawn Time.
var column: int = -1 ## Note Column/Direction.
var side: int = -1 ## Note Player ID/Side.[br]0 = Enemy, 1 = Player, etc...
## Note Type/Kind, if unspecified or non-existant,
## The default note type will be used instead.
var kind: StringName
## Note Length, spawns a tail in the note if specified.
var length: float = -1.0

# Input stuff
var was_hit: bool = false
var was_missed: bool = false
var hit_misses: bool = false ## Hitting this note will cause a miss instead.
#var late_hitbox: float = 1.0
#var early_hitbox: float = 1.0
var hit_time: float = 0.0
var judgement: Judgement
# FOR HOLDS
var dropped: bool = false
var trip_timer: float = 1.0
var _stupid_visual_bug: bool = false
# VISUALS
@onready var scroll_mult: Vector2 = Vector2(-1, 1)
var moving: bool = true

func hide_all() -> void: queue_free()
func show_all() -> void: show()

## Override this to allow the note to have a note splash.
func can_splash() -> bool:
	return false

var _strum: StrumNote

func _ready() -> void:
	if has_node("clip_rect"):
		clip_rect = get_node("clip_rect")
		if has_node("clip_rect/hold_body"): hold_body = get_node("clip_rect/hold_body")
		if has_node("clip_rect/hold_tail"): hold_tail = get_node("clip_rect/hold_tail")
	reset_scroll()

func reset_scroll() -> void:
	match Global.settings.scroll:
		0: scroll_mult.y *= -1
		1: scroll_mult.y *=  1
	clip_rect.scale *= -scroll_mult

func get_total_speed() -> float:
	var markplier: float = (Note.SM_SPEED_MULT if Note.USE_SM_SCROLL else 1.5)
	if Global.settings.use_custom_note_speed:
		return Global.settings.note_speed * markplier
	else:
		var strums_speed: float = strumline.speed * strumline.get_strum(column).speed
		return strums_speed * markplier

func scroll_ahead() -> void:
	var note_speed: float = get_total_speed()#Conductor.bpm
	var relative: float = (time - Conductor.playhead)
	position.y = _strum.position.y # making sure
	if Note.USE_SM_SCROLL:
		# Stepmania/ITG speed handling https://github.com/openitg/openitg/blob/f2c129fe65c65e4a9b3a691ff35e7717b4e8de51/src/ArrowEffects.cpp#L42
		var next_y: float = relative * note_speed * Note.SM_ARROW_SIZE
		position.y += next_y * -scroll_mult.y #/ absf(scale.y)
	else:
		# classic FNF speed stuff, readded for testing.
		position.y += 450.0 * (relative * note_speed) * -scroll_mult.y

func update_hold(_delta: float) -> void:
	moving = false
	position.y = _strum.position.y
	if not clip_rect.z_index == -1:
		clip_rect.z_index = -1
	if _stupid_visual_bug and not Note.USE_SM_SCROLL:
		hold_size += hit_time / absf(clip_rect.scale.y)
		_stupid_visual_bug = false
	hold_size = (time + length) - Conductor.playhead
	display_hold(hold_size, get_total_speed())
	if (hold_size <= 0.0 or trip_timer <= 0.0):
		hide_all()

## Override this function to do something when you finish holding all the way through.
func hold_finished() -> void:
	pass

## Use this function to initialise the note itself and related properties[br]
## Called whenever a note is spawned, remember to also call super(data)
func reload(p_data: NoteData) -> void:
	data = p_data
	if strumline: # for convenience.
		_strum = strumline.strums[p_data.column]
		if _strum: position = _strum.position
	hold_size = p_data.length
	_stupid_visual_bug = false
	moving = is_instance_valid(_strum)
	was_missed = false
	was_hit = false

## Use this function for implementing hold note visuals.[br]
## Leave empty if you want your note type to not have holds.
func display_hold(size: float = 0.0, speed: float = -1.0) -> void:
	if speed <= 0.0: speed = get_total_speed()
	if column != -1 and not hold_body or not clip_rect:
		return
	 # URGHHHHHHHHHHH
	if Note.USE_SM_SCROLL:
		speed *= Note.SM_ARROW_SIZE
	else:
		speed *= 500.0
	# general implementation, should work for everything???
	if hold_body.texture:
		hold_body.size.x = hold_body.texture.get_width()
		hold_body.size.y = (size * speed) / absf(clip_rect.scale.y)

## Use this function for implementing splash visuals.[br]
## Return null if you don't want note splashes on your note type.
func display_splash() -> Node2D:
	return null

## Checks if the note is in range to be hitp
func is_hittable(hit_window: float = 0.18) -> bool:
	#const diff: float = data.time - Conductor.playhead
	#return absf(diff) <= (hit_window * (early_hitbox if diff < 0 else late_hitbox))
	return absf(Conductor.playhead - time) <= hit_window and not was_hit and not was_missed
