extends FunkinStage2D

@onready var crowd: AnimatedSprite2D = $"%little guys"
@onready var green_light: Sprite2D = $%lightgreen # GREEN LIGHTTTTT
@onready var red_light: Sprite2D = $%lightred # RED LIGHT

var lights_alpha: float = 1.0

func _ready() -> void:
	crowd.frame = 0
	crowd.play("Symbol 2 instance 1")

# doesn't work lol??? idk
func _process(_delta: float) -> void:
	lights_alpha -= lerpf(0.1, lights_alpha, 0.05)
	green_light.modulate.a = lights_alpha
	red_light.modulate.a = lights_alpha

func on_beat_hit(beat: float) -> void:
	super(beat)
	if int(beat) % 4 == 0:
		lights_alpha = 1.0
