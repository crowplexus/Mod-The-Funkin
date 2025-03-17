## Resource used for skinning notes.
class_name NoteSkin
extends Resource

## SpriteFrames used for the Note Fields
@export var field_texture: SpriteFrames
## SpriteFrames used for the Tap Notes and Hold Notes
@export var note_textures: Dictionary[String, SpriteFrames]
## SpriteFrames used for the Note Splashes (show up when you hit a Sick! or Epic!! on notes)
@export var splash_textures: Dictionary[String, SpriteFrames]
