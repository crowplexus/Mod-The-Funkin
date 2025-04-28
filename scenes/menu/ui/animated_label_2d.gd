class_name AnimatedLabel2D extends Control

enum CharacterType {
	BOLD = 0,
	NORMAL = 1,
}

const PLACEHOLDER_CHARACTER: String = "question mark"
const PLACEHOLDER_OFFSET: Vector2 = Vector2(5, 0)

const LATIN_LETTERS: String = "abcdefghijklmnopqrstuvwxyz"
const LATIN_ACCENTS: String = "áéíóúýàèìòùâêîôûãõñçäëïöüÿ"
const CYRILLIC_LETTERS: String = "абвгдеёжзийклмнопрстуфхцчшщъыьэюяѓѕјќљњџ"
# I'll leave these here just in case I support those langauges someday.
#const CYRILLIC_SERBIAN: String = "ђжјљњћџ"
#const CYRILLIC_UKRAINIAN: String = "ґєії"

## The [code]SpriteFrames[/code] resource containing the animation(s).
## Allows you the option to load, edit, clear, make unique and save the states of the [code]SpriteFrames[/code] resource.
@export var sprite_frames: SpriteFrames
## Spacing between each letter and paragraph.
@export var spacing: Vector2 = Vector2(30, 65)
@export_multiline var text: String = "":
	set(new_text):
		text = new_text.replace("\\n", "\n")
		display_letters()
## Current variant of the charaters.
@export var variant: CharacterType = CharacterType.BOLD
@export_enum("Left:0", "Center:1", "Right:2")#, "Fill:3")
var alignment: int = 0:
	set(new_alignment):
		alignment = new_alignment
		update_alignment()
@export var auto_scale: bool = true ## Lines will scale themselves if too big.

func display_letters() -> void:
	if not sprite_frames:
		push_error("No SpriteFrames are set for this AnimatedLabel2D! please set the SpriteFrames variable!")
		return
	
	for i: Control in get_children():
		for v: Node in i.get_children():
			v.queue_free()
		i.queue_free()
	
	var next_offset: Vector2 = Vector2(0, 35)
	var line: Control = Control.new()
	line.name = "line%s" % get_child_count()
	for idx: int in text.length():
		var tchar: String = text[idx]
		var is_space: bool = tchar == " "
		var line_break: bool = tchar == "\n"
		if line_break:
			if auto_scale and line.size.x > size.x:
				line.scale.x = size.x / line.size.x
			add_child(line)
			line = Control.new()
			line.name = "line%s" % get_child_count()
			next_offset.x = 0
			next_offset.y += spacing.y
			continue
		if is_space:
			next_offset.x += spacing.x
			continue
		if sprite_frames:
			var new_char: AnimatedSprite2D = generate_character(tchar)
			var texture: Texture2D = sprite_frames.get_frame_texture(new_char.animation, 0)
			if texture:
				var width: float = sprite_frames.get_frame_texture(new_char.animation, 0).get_width()
				#var height: float = sprite_frames.get_frame_texture(new_char.animation, 0).get_height()
				var add_size_x: float = width + new_char.offset.x
				new_char.position += next_offset
				next_offset.x += add_size_x
				line.size.x = next_offset.x
			line.add_child(new_char)
	if auto_scale and line.size.x > size.x:
		line.scale.x = size.x / line.size.x
	add_child(line)
	update_alignment()

func generate_character(tchar: String, type: CharacterType = variant) -> AnimatedSprite2D:
	var offset: Vector2 = Vector2.ZERO
	var character: AnimatedSprite2D = AnimatedSprite2D.new()
	character.sprite_frames = sprite_frames
	var is_letter: bool = LATIN_LETTERS.contains(tchar.to_lower()) #or CYRILLIC_LETTERS.contains(char.to_lower())
	var char_anim: String = tchar.to_snake_case()
	var char_offset: Vector2 = Vector2.ZERO
	if is_letter:
		match type:
			CharacterType.BOLD:
				char_anim = tchar.to_upper() + " bold"
			CharacterType.NORMAL:
				char_anim = tchar.to_upper() + " capital"
				if tchar.to_lower() == tchar:
					char_anim = tchar.to_lower() + " lowercase"
	else:
		match tchar.to_snake_case(): # offsets really only apply for Bold variant for nows…
			"!":
				char_anim = "exclamation point"
				char_offset = Vector2(-10, -10)
			"#": char_anim = "hashtag"
			",": char_anim = "comma"
			".":
				char_anim = "period"
				char_offset = Vector2(-10, 25)
			"/":
				char_anim = "forward slash"
			"♥":
				char_anim = "heart"
			"😠":
				char_anim = "angry faic"
				char_offset = Vector2(10, -3)
			"$":
				char_anim = "dollarsign "
			"(", ")":
				char_offset.x = -10
			"-":
				char_offset.x = -8
			"_":
				char_offset.y = 25
	if not sprite_frames.has_animation(char_anim):
		character.animation = PLACEHOLDER_CHARACTER
		character.offset = PLACEHOLDER_OFFSET
		return character
	else:
		character.animation = char_anim
		character.offset = char_offset
	return character

func update_alignment() -> void:
	for line: Control in get_children():
		line.position = Vector2.ZERO
		var scaled_width: float = line.size.x * line.scale.x
		#var scaled_heght: float = line.size.y * line.scale.y
		match alignment:
			0: line.position.x = 0
			1: line.position.x = ((size.x - scaled_width) * 0.5)
			2: line.position.x = (size.x - scaled_width)
