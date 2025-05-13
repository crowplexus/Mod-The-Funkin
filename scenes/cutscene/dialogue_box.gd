class_name DialogueBox extends Control

signal dialogue_skipped(convo: Conversation)
signal dialogue_progressed(convo: Conversation)
signal character_popped(convo: Conversation, char: int)

const INPUT_DELAY: float = 0.1 # 100ms
const WRITER_DELAY: float = 0.3 # 300ms
const SOUNDLESS_CHARS: PackedStringArray = ["", " ", "\n", "\t", "\r"]

@export var animation: AnimationPlayer
@export var default_write_sound: AudioStream = preload("res://assets/sounds/dialogue/pixelText.ogg") ## Default sound used when there's no character speaking.
@export var default_writing_speed: float = 25.0 ## Characters per second.
@export var conversation: ConversationArray

var current_character: int = 0
var current_writing_speed: float = 1.0
var current_convo_idx: int = -1
var current_dialogue: Conversation:
	get: return conversation.list[current_convo_idx % conversation.size()]
var is_writing: bool = false

var _input_delay: float = 0.0
var _writer_pause: float = 0.0
var _character_accum: float = 0.0
var _last_character: int = -1
var _last_anim: StringName
# KIND OF A WORKAROUND FOR SOUND BEEPS
var _bbcode_regex = RegEx.new()

func _ready() -> void:
	_bbcode_regex.compile("\\[.*?\\]")
	current_writing_speed = default_writing_speed
	if animation.has_animation("open"):
		play_animation("open")
		await animation.animation_finished
	await get_tree().create_timer(WRITER_DELAY).timeout
	_writer_pause = 0.0
	progress_dialogue()

func _process(delta: float) -> void:
	if _input_delay > 0.0: _input_delay -= delta
	if _writer_pause > 0.0: _writer_pause -= delta
	if not is_writing or _writer_pause > 0.0:
		return
	_character_accum += delta * current_writing_speed
	update_characters()

func update_characters() -> void:
	if _character_accum >= 1.0:
		var how_much: int = floori(_character_accum)
		current_character = clampi(current_character + how_much, 0, current_dialogue.text.length())
		_character_accum -= how_much
		character_popped.emit(current_dialogue, current_character)
	
	if current_character > _last_character:
		for i: int in range(_last_character, current_character):
			if i < current_dialogue.text.length():
				var cur_text: String = current_dialogue.text[i]
				if can_play_sound(cur_text, i):
					play_dialogue_sound(cur_text, i)
					break # prevent ear-bleeding sound playback
		_last_character = current_character
	
	if current_character >= current_dialogue.text.length():
		is_writing = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not is_writing and _input_delay > 0.0:
		return
	if Input.is_action_just_pressed("ui_accept"):
		_input_delay = INPUT_DELAY
		if current_character < current_dialogue.text.length():
			current_character = current_dialogue.text.length()
			if animation.has_animation("skip"):
				play_animation("skip")
			dialogue_skipped.emit(current_dialogue)
			return
		if animation.has_animation("confirm"):
			play_animation("confirm")
			await animation.animation_finished
		progress_dialogue()

func play_animation(anim_name: StringName, force: bool = false) -> void:
	if not animation or not animation.has_animation(anim_name):
		push_error("AnimationPlayer for dialogue box is either not set or tried playing an inexistent animation (",anim_name,")")
	if force or anim_name != _last_anim:
		animation.seek(0.0)
	animation.play(anim_name)
	_last_anim = anim_name

func display_dialogue() -> void:
	_character_accum = 0.0
	current_character = 0
	_last_character = -1
	dialogue_progressed.emit(current_dialogue)

func progress_dialogue() -> void:
	if conversation.is_empty() or (current_convo_idx + 1) > conversation.size()-1:
		if conversation.is_empty(): push_warning("There's no conversation to be had, bye.")
		if animation.has_animation("close"):
			play_animation("close")
			await animation.animation_finished
		queue_free()
		return
	current_convo_idx = clampi(current_convo_idx + 1, 0, conversation.size()-1)
	_writer_pause = WRITER_DELAY
	display_dialogue()
	is_writing = true

func _is_bbcode_char(text: String, index: int) -> bool:
	for result in _bbcode_regex.search_all(text):
		if result.get_start() <= index and result.get_end() > index:
			return true
	return false

func can_play_sound(text_char: String, index: int) -> bool:
	if text_char in SOUNDLESS_CHARS:
		return false
	var open_pos = current_dialogue.text.rfind("[", index)
	if open_pos != -1 and current_dialogue.text.find("]", open_pos) > index:
		return false
	return true

func play_dialogue_sound(_char: String, _index: int) -> void:
	# override for custom behaviour.
	pass
