class_name Actor2D
extends Node2D

## Beat delay for the character to bop its head.
@export var dance_interval: float = 2.0
## Dance Animations for the character to play every dance interval.
@export var dance_moves: PackedStringArray = ["idle"]
## Sing Animations for the character to play when hitting the corresponding notes.
@export var sing_moves: PackedStringArray = ["singLEFT", "singDOWN", "singUP", "singRIGHT"]
## How long it takes for a character to stop singing after doing so.
@export var sing_duration: float = 2.0
## Icon shown on the health bar.
@export var icon: HealthIcon
## Mark the character as a player (flips certain animations when its used as an opponent).
@export var is_player: bool = false
## Scene used for when the character dies and gets sent to the game over sequence.[br]
## Keep in mind, this character must have the following animations, named exactly like so:[br][br]
## "deathStart" -> plays when the game over sequence shows up.[br]
## "deathLoop" -> plays while no buttons are being pressed after the first death animation.[br]
## "deathConfirm" -> plays after pressing accept to end the game over sequence.[br]
@export var death_skeleton: PackedScene = load("res://scenes/gameplay/characters/bf-dead.tscn")
## Sound played when the character dies and gets sent to the game over sequence.[br]
## Keep in mind, change this in the skeleton scene itself, not in its parent.
@export var death_sound: AudioStream = preload("res://assets/sounds/gameover/fnf_loss_sfx.ogg")
## Sound played when the you press enter to retry in the game over sequence.[br]
## Keep in mind, change this in the skeleton scene itself, not in its parent.
@export var death_confirm_sound: AudioStream = preload("res://assets/music/gameover/gameOverEnd.ogg")
## Music to play in the background for the game over sequence.[br]
## Keep in mind, change this in the skeleton scene itself, not in its parent.
@export var death_music: AudioStream = preload("res://assets/music/gameover/gameOver.ogg")
## Animation Player attached to the Actor, prevents animations from playing altogether if null.
var anim: AnimationPlayer
## Time (in seconds) to snap the character back to its idle animations.
var idle_cooldown: float = 0.0
## If set to [code]true[/code], the character won't be able to idle until otherwise.
## Function to make the character dance, uses a generic method by default.
var dance_sequence: Callable = func(beat: float) -> void:
	if dance_interval > 0.0 and int(beat * 100) % int(dance_interval * 100) and idle_cooldown <= 0.0:
		dance()

var pause_sing: bool = false
var faces_left: bool = false
var _last_anim: String = ""
var _last_dance: int = 0

func _ready() -> void:
	if has_node("animation_player"): anim = get_node("animation_player")
	if dance_sequence: Conductor.on_beat_hit.connect(dance_sequence)
	if not is_player and faces_left:
		scale.x *= -1

func _exit_tree() -> void:
	if dance_sequence: Conductor.on_beat_hit.disconnect(dance_sequence)

func _process(delta: float) -> void:
	if idle_cooldown > 0.0 and not pause_sing:
		idle_cooldown -= delta / (Conductor.crotchet * sing_duration)
		if idle_cooldown <= 0.0:
			dance()

func play_animation(animation: String, forced: bool = false, reversed: bool = false, speed: float = 1.0) -> void:
	if not anim or not anim.has_animation(animation): return
	if _last_anim != animation or forced: anim.seek(0.0)
	anim.play(animation, -1, speed, reversed)
	_last_anim = animation

func dance(forced: bool = false, reversed: bool = false, speed: float = 1.0) -> void:
	play_animation(dance_moves[_last_dance], forced, reversed, speed)
	_last_dance = wrapi(_last_dance + 1, 0, dance_moves.size())

func sing(direction: int, forced: bool = false, suffix: String = "", reversed: bool = false, speed: float = 1.0) -> void:
	play_animation(sing_moves[direction % sing_moves.size()] + suffix, forced, reversed, speed)
	idle_cooldown = 1.0

func get_anim_position() -> float:
	return anim.current_animation_position if anim else 0.0

func die() -> void:
	if not death_skeleton:
		return
	hide()
	var game_over_screen: PackedScene = load("res://scenes/gameplay/adjacent/game_over.tscn")
	var instance: Node2D = game_over_screen.instantiate()
	instance.process_mode = Node.PROCESS_MODE_ALWAYS
	# spawn skeleton
	var pos: Vector2 = self.global_position
	if instance.has_node("skeleton"):
		instance.get_node("skeleton").queue_free()
	instance.skeleton = death_skeleton.instantiate()
	instance.skeleton.global_position = pos
	instance.skeleton.name = "skeleton"
	instance.add_child(instance.skeleton)
	instance.move_child(instance.skeleton, 1)
	get_tree().paused = true
	# add the scene to to where it should be.
	#if get_tree().current_scene is Gameplay:
	#	get_tree().current_scene.hud_layer.add_child(instance)
	#else:
	get_tree().current_scene.add_child(instance)
	instance._start_game_over()
