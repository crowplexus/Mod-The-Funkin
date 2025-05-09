## Judgement Data.
class_name Judgement extends Resource

## Defines which kind of note splash should show up when hitting the judgement.
enum SplashType {
	DISABLED = 0,
	WEAK = 1,
	FULL = 2
}

@export var name: StringName = &"Unknown" ## Display Name of the judgement.
@export var splash_type: SplashType = SplashType.DISABLED ## Define if the judgement spawns a note splash, and which kind of note splash.
@export var combo_break: bool = false ## If the judgement causes a combo break.
@export var color: Color = Color.WHITE ## The color of the judgement.
@export var health_bonus: int = 0 ## How much health points should you get from this judgement.
