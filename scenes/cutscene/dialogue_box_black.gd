extends DialogueBox

@onready var sound: AudioStreamPlayer = $"writing_sound"
@onready var writer: RichTextLabel = $"text"

func _ready() -> void:
	writer.visible_characters = 0
	dialogue_progressed.connect(func(convo: Conversation) -> void:
		writer.text = convo.text
		writer.visible_characters = 0)
	dialogue_skipped.connect(func(convo: Conversation) -> void:
		writer.text = convo.text
		writer.visible_characters = -1)
	character_popped.connect(func(_convo: Conversation, char_idx: int) -> void:
		writer.visible_characters = char_idx)
	super()

func play_dialogue_sound(_char: String, _index: int) -> void:
	if current_dialogue.speaking_sound and sound.stream != current_dialogue.speaking_sound:
		sound.stream = current_dialogue.speaking_sound
	elif not is_instance_valid(current_dialogue.speaking_sound):
		sound.stream = default_write_sound
	if sound and sound.stream: sound.play()
