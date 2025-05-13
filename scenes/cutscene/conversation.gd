class_name Conversation extends Resource
@export_multiline var text: String = "" ## Text to display.
@export_category("Character")
@export var speaker: String = "bf" ## Name of current speaker.
@export var mood: String = "normal" ## Mood of current speaker.
#@export var priority: int = 0 ## TODO: add interruptions.
@export var portrait: Texture2D ## Portrait of current speaker.
@export var speaking_sound: AudioStream ## Sound the current speaker makes when text scrolls.
