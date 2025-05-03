extends Note

@onready var animation: AnimationPlayer = $"animation_player"
@onready var arrow: Sprite2D = $"arrow"

func reload(p_data: NoteData) -> void:
	super(p_data)
	hit_misses = true
	animation.play("mine")
	if hold_size > 0.0: hold_size = 0.0 # can't
	if not arrow.visible: arrow.show_all()
