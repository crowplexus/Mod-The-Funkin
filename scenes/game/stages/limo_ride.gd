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
@onready var drive_timers: Array[Timer] = [
	$"factor(1,1)/car/timer",
	$"factor(1,1)/carr/timer"
]
@onready var driver_wait_tmr: Timer = $"driver_wait"
var car_origins: Array[Vector2] = []
var danced: bool = false

func _ready() -> void:
	car_origins.resize(cars.size())
	for car: PhysicsSprite2D in cars:
		var index: int = cars.find(car)
		car_origins[index] = car.position
		drive_timers[index].timeout.connect(func() -> void:
			reset_fast_car(car)
		)
	super()

func on_beat_hit(beat: float) -> void:
	super(beat)
	if floori(beat) % 1 == 0:
		dancer_animation.seek(0.0)
		dancer_animation.play("dance" + ("Right" if danced else "Left"))
		danced = not danced
		var chance: bool = randi_range(0, 100) < 50
		if chance: fast_car_drive()

func fast_car_drive() -> void:
	var car: PhysicsSprite2D = cars.pick_random()
	var car_index: int = cars.find(car)
	if car.position == car_origins[car_index]:
		driver_wait_tmr.start()
		car_pass.stream = fast_car_sounds.pick_random()
		car_pass.play(0.0)
		await driver_wait_tmr.timeout
		var car_speed: float = (randi_range(70, 120) / get_process_delta_time()) * 3
		if car == fast_car_left: car.velocity.x += car_speed
		else: car.velocity.x -= car_speed
		drive_timers[car_index].start()
		car.moving = true

func reset_fast_car(car: PhysicsSprite2D) -> PhysicsSprite2D:
	var car_index: int = cars.find(car)
	car.moving = false
	car.position.x = car_origins[car_index].x
	car.velocity.x = 0
	return car
