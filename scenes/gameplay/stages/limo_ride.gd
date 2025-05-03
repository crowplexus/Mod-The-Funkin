extends FunkinStage2D

@export var fast_car_sounds: Array[AudioStream] = [
	preload("res://assets/game/backgrounds/week4/carPass0.ogg"),
	preload("res://assets/game/backgrounds/week4/carPass1.ogg")
]

@onready var dancer_animation: AnimationPlayer = $"dancers_animator"
@onready var fast_car_left: PhysicsSprite2D = $"factor(1,1)/car"
@onready var fast_car_right: PhysicsSprite2D = $"factor(1,1)/carr"
@onready var cars: Array[PhysicsSprite2D] = [fast_car_left, fast_car_right]
@onready var car_pass: AudioStreamPlayer = $"car_pass_player"

var a_car_is_driving: bool = false
var drive_timers: Array[Timer] = []
var car_origins: Array[Vector2] = []
var danced: bool = false

func _ready() -> void:
	for car: PhysicsSprite2D in cars:
		car_origins.append(car.position)
		drive_timers.append(Timer.new())
		drive_timers.back().name = car.name + "_timer"
		drive_timers.back().timeout.connect(func() -> void: reset_fast_car(car))
		drive_timers.back().autostart = false
		add_child(drive_timers.back())

func on_beat_hit(beat: float) -> void:
	super(beat)
	if floori(beat) % 1 == 0:
		dancer_animation.seek(0.0)
		dancer_animation.play("dance" + ("Right" if danced else "Left"))
		danced = not danced
		# TODO: why does this not work lol.
		if randi_range(0, 100) < 50 and not a_car_is_driving:
			a_car_is_driving = true
			fast_car_drive()

func fast_car_drive() -> void:
	car_pass.stream = fast_car_sounds.pick_random()
	var car: PhysicsSprite2D = cars.pick_random()
	var car_speed: float = (randi_range(170, 220) / get_process_delta_time()) * 3
	if car == fast_car_left: car.velocity.x += car_speed
	else: car.velocity.x -= car_speed
	var car_index: int = cars.find(car)
	drive_timers[car_index].start(2)
	car_pass.play(0.0)

func reset_fast_car(car: PhysicsSprite2D) -> void:
	car.position.x = car_origins[cars.find(car)].x
	a_car_is_driving = false
	car.velocity.x = 0
