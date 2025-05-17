class_name PhysicsSprite2D extends Sprite2D

@export var velocity: Vector2 = Vector2.ZERO
@export var acceleration: Vector2 = Vector2.ZERO
@export var moving: bool = true

var initial_velocity: Vector2 = Vector2.ZERO
var initial_acceleration: Vector2 = Vector2.ZERO

func _ready() -> void:
	initial_velocity = velocity
	initial_acceleration = acceleration

func _physics_process(delta: float) -> void:
	if moving: update_velocity(delta)

func update_velocity(delta: float) -> void:
	# I don't *need* to do this but I want the flixel sovl.
	var half_velocity: Vector2 = (velocity + acceleration * delta) * 0.5
	velocity += acceleration * delta
	position += half_velocity * delta

func random_velocity(min_speed_x: float = -10.0, max_speed_x: float = 10.0, min_speed_y: float = -10.0, max_speed_y: float = 10.0) -> void:
	velocity = Vector2(randf_range(min_speed_x, max_speed_x), randf_range(min_speed_y, max_speed_y))
