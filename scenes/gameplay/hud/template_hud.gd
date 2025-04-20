class_name TemplateHUD extends Control

## Called whenever the countdown ticks.
@warning_ignore("unused_signal") # shut UP?
signal on_countdown_tick(tick: int)
## Called whenever the countdown ends.
@warning_ignore("unused_signal") # shut UP?
signal on_countdown_end()

## Use this if you want to skip the default hud countdown.
@export var skip_countdown: bool = false

func settings_changed(_settings: Settings) -> void:
	pass
			
## Returns the lerp value used for decreasing the hud scale for beat zooms.
func get_bump_lerp(_from: float = 2.0, to: float = 1.0, _delta: float = 0) -> float:
	return to

## Returns the lerp value used for decreasing the hud scale as a vector.
func get_bump_lerp_vector(_from: Vector2 = Vector2.ONE, to: Vector2 = Vector2.ONE, _delta: float = 0) -> Vector2:
	return to

## Returns the value used for increasing the hud scale for beat zooms.
func get_bump_scale() -> float:
	return 1.0

## Use this to initialize the HUD's default values (if needed).
func init_vars() -> void:
	pass

## Displays the countdown and does something after it ends.
func start_countdown() -> void:
	pass

## Updates the score text to display new stats.
func update_score_text(_missed: bool = false) -> void:
	pass

## Updates the health bar to display a new value.
func update_health(_health: int) -> void:
	pass

@warning_ignore("unused_parameter")
## Displays a judgement sprite on-screen.
func display_judgement(judgement: Judgement) -> void:
	pass

@warning_ignore("unused_parameter")
## Displays combo count on-screen.
func display_combo(combo: int = -1) -> void:
	pass
