class_name HealthIcon extends Resource

# TODO: change how health icons work entirely.

## Icon to be added to the health bar.
@export var texture: Texture2D
## Color to be used in the health bar.
@export var color: Color = Color("#808080")
## How many horizontal frames the icon has.
@export var hframes: int = 2
## How many vertical frames the icon has.
@export var vframes: int = 1

## Returns the current icon frame according to health.
func get_frame(health: int) -> int:
	return (1 if health <= 20 else 0) if hframes > 1 else 0
