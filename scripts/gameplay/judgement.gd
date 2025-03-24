## Judgement Data.
class_name Judgement
extends Resource

enum SplashType {
	DISABLED = 0,
	WEAK = 1,
	FULL = 2
}

## Display Name of the judgement.
@export var name: StringName = &"Unknown"
## Texture displayed when hitting the judgement,
## Leave empty if you want it to be invisible.
@export var texture: Texture2D = null
## Define if the judgement spawns a note splash, and which kind of note splash.
@export var splash_type: SplashType = SplashType.DISABLED
## If the judgement causes a combo break.
@export var combo_break: bool = false
