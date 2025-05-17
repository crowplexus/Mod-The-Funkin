extends Note

@onready var animation: AnimationPlayer = $"animation_player"
@onready var arrow: Sprite2D = $"arrow"

func reload(p_data: NoteData) -> void:
	super(p_data)
	is_mine = true
	animation.play("mine")
	if hold_size > 0.0: hold_size = 0.0 # can't
	show_all()

func on_note_hit() -> void:
	if strumline.input.botplay: return # prevent bot missing.
	strumline.play_strum(StrumNote.States.PRESS, column, true)
	strumline.input.on_note_miss(self, column)
	hide_all()

func on_note_miss() -> void:
	# just hide it.
	hide_all()
