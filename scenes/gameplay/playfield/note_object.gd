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
		anim_suffix = new_data.anim_suffix
		raw_time = new_data.time
		column = new_data.column
		length = new_data.length
		kind = new_data.kind
		side = new_data.side
## (Current) Hold Size, not to be confused with [code]data.length[/code]
var hold_size: float = 0.0
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
## Animation Suffix for the note.
var anim_suffix: String = ""

# Input stuff
var was_hit: bool = false
var was_missed: bool = false
var hit_by_bot: bool = false
var is_mine: bool = false
#var late_hitbox: float = 1.0
#var early_hitbox: float = 1.0
var hit_time: float = 0.0
var judgement: StringName = &"none"
var splash_type: = Judgement.SplashType.DISABLED
# FOR HOLDS
var dropped: bool = false
var trip_timer: float = 1.0
var _stupid_visual_bug: bool = false
# VISUALS
@onready var scroll_mult: Vector2 = Vector2(-1, 1)
@onready var _old_sm: Vector2 = Vector2.ZERO
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
	reset_scroll()

func _process(_delta: float) -> void:
	if visible and _strum and moving:
		follow_strum()

func reset_scroll() -> void:
	if not clip_rect: return
	match Global.settings.scroll:
		0: scroll_mult.y *= -1
		1: scroll_mult.y *=  1
	if _old_sm != scroll_mult:
		clip_rect.scale *= -scroll_mult
	_old_sm = scroll_mult

func get_total_speed() -> float:
	var markplier: float = (Note.SM_SPEED_MULT if Note.USE_SM_SCROLL else 1.5)
	var speed: float = strumline.speed * strumline.get_strum(column).speed
	match Global.settings.note_speed_mode:
		2: speed = Global.settings.note_speed # Constant/C-Mod
		1: speed = speed * Global.settings.note_speed # Multiplicative/A-Mod
		3: speed = Global.settings.note_speed * (Conductor.bpm / 60.0) # BPM-Based/X-Mod
	return speed * markplier

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
	if (hold_size <= 0.0 or trip_timer <= 0.0):
		hide_all()

## Override this function to do something when you hit the note.
func on_note_hit() -> void:
	strumline.input.on_note_hit(self)

## Override this function to do something when you miss the note.
func on_note_miss() -> void:
	strumline.input.on_note_miss(self, column)
	was_missed = true

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
func calculate_hold_y_size(size: float = 0.0, speed: float = -1.0) -> float:
	if column <= -1:
		return 0.0
	if speed <= 0.0: speed = get_total_speed()
	 # URGHHHHHHHHHHH
	if Note.USE_SM_SCROLL:
		speed *= Note.SM_ARROW_SIZE
	else:
		speed *= 500.0
	# general implementation, should work for everything???
	return (size * speed) / absf(clip_rect.scale.y)

## Use this function for implementing splash visuals.[br]
## Return null if you don't want note splashes on your note type.
func display_splash() -> Node2D:
	return null

## Checks if the note is in range to be hitp
func is_hittable(hit_window: float = 0.18) -> bool:
	#const diff: float = data.time - Conductor.playhead
	#return absf(diff) <= (hit_window * (early_hitbox if diff < 0 else late_hitbox))
	return absf(Conductor.playhead - time) <= hit_window and not was_hit and not was_missed

func follow_strum() -> void:
	if moving: scroll_ahead()
	# preventing orphan nodes hopefully with this.
	if not was_hit and (Conductor.playhead - time) > 0.75:
		if strumline and strumline.input:
			var miss_delay: float = 0.75 if strumline.input.botplay else 0.3
			if miss_delay == 0.3 and not was_hit:
				on_note_miss()
		if is_inside_tree(): # not null by the time on_note_miss is called
			hide_all()
			strumline.on_note_deleted.emit(self)
