extends Actor2D

const MISS_COLOR: Color = Color("#8c96ff")

var missing: bool = false
var normal_color: Color = Color.WHITE

func _ready() -> void:
	super()
	normal_color = self.modulate

func _process(delta: float) -> void:
	super(delta)
	if missing and idle_cooldown <= 0.0:
		missing = false
		modulate = normal_color

func sing(direction: int, forced: bool = false, suffix: String = "", reversed: bool = false, speed: float = 1.0) -> void:
	if faces_left:
		match direction: # ah
			3: direction = 0
			0: direction = 3
	if suffix == "miss":
		missing = true
		play_animation(sing_moves[direction % sing_moves.size()], forced, reversed, speed)
		idle_cooldown = 0.8
		modulate = MISS_COLOR
	else:
		missing = false
		modulate = normal_color
		play_animation(sing_moves[direction % sing_moves.size()] + suffix, forced, reversed, speed)
		idle_cooldown = 1.0
