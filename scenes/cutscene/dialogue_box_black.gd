extends DialogueBox

@onready var sound: AudioStreamPlayer = $"writing_sound"
@onready var confirm_sfx: AudioStream = preload("res://assets/sounds/dialogue/textboxClick.ogg")
@onready var writer: RichTextLabel = $"text"

func _ready() -> void:
	var started: bool = true
	writer.visible_characters = 0
	dialogue_progressed.connect(func(convo: Conversation) -> void:
		writer.text = convo.text
		writer.visible_characters = 0
		if not started: Global.play_sfx(confirm_sfx)
	)
	dialogue_skipped.connect(func(convo: Conversation) -> void:
		writer.text = convo.text
		writer.visible_characters = -1
		Global.play_sfx(confirm_sfx)
	)
	character_popped.connect(func(_convo: Conversation, char_idx: int) -> void:
		writer.visible_characters = char_idx)
	super()
	started = false

func play_dialogue_sound(_char: String, _index: int) -> void:
	if current_dialogue.speaking_sound and sound.stream != current_dialogue.speaking_sound:
		sound.stream = current_dialogue.speaking_sound
	elif not is_instance_valid(current_dialogue.speaking_sound):
		sound.stream = default_write_sound
	if sound and sound.stream: sound.play()
