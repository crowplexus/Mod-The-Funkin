### Timed Events are very basic event types that contain a [code]time[/code]
### field, which is used to trigger the event during gameplay.
class_name TimedEvent extends Resource

@export var name: StringName ## Name of the event.
@export var time: float ## Time (in seconds).
@export var eload: Callable ## Function to run when the event loads.
@export var efire: Callable ## Function to run whenever the event gets fired.
@export var values: Dictionary = {} ## Internal values in the event.
var was_fired: bool = false ## Internal value, indicates that the event has already been fired, so no point in doing it again.

static func sort_by_time(one: TimedEvent, two: TimedEvent) -> int:
	return one.time < two.time

func _to_string() -> String:
	return "[%s, %s, %s]" % [ name, time, values ]

#region Event Presets

### Returns a Velocity Change event.
static func velocity_change(_time: float, speed: float = 1.0, immediate: bool = false) -> TimedEvent:
	var vc: = TimedEvent.new()
	vc.name = &"Change Scroll Speed"
	vc.efire = func() -> void:
		if Gameplay.current:
			for note_field: NoteField in Gameplay.current.note_fields.get_children():
				TimedEvent.change_scrolL_speed_event(note_field, speed, immediate)
	vc.values.speed = speed
	vc.time = _time
	return vc

# Returns a BPM Change event, no longer needed since the Conductor handles it itself.
#static func bpm_change(_time: float, bpm: float = 100.0) -> TimedEvent:
#	var vc: = TimedEvent.new()
#	vc.name = &"BPM Change"
#	vc.time = _time
#	vc.values.bpm = bpm
#	vc.efire = func() -> int:
#		Conductor.bpm = vc.values.bpm
#		return vc.values.bpm
#	return vc

#endregion

#region Recurring Gameplay Events

static func play_animation_event(animation: String, force: bool = false, target: int = 0, cooldown: float = 0.0) -> void:
	if not Gameplay.current:
		return
	var game: Gameplay = Gameplay.current
	var actor: Actor2D = game.get_actor_from_index(target)
	if actor and actor.has_animation(animation):
		actor.play_animation(animation, force)
		if is_zero_approx(cooldown):
			actor.idle_cooldown = actor.get_anim_length(0.5) + 0.1
		else:
			actor.idle_cooldown = cooldown
		actor.able_to_sing = false
		actor.lock_on_sing = false

static func change_scrolL_speed_event(note_field: NoteField, speed: float, immediate: bool = false) -> void:
	if not immediate:
		note_field.speed_change_tween = note_field.create_tween()
		note_field.speed_change_tween.tween_property(note_field, "speed", speed, 1.0)
	else:
		note_field.speed = speed

# TODO: figure out a way of making the camera events not bound to gameplay.
static func zoom_camera_event(zoom: float = 1.0) -> void:
	if Gameplay.current and Gameplay.current.camera:
		# TODO: add duration, easing, and mode.
		Gameplay.current.camera.zoom = Vector2(zoom, zoom)

static func focus_camera_event(char: int = -1, x: float = 0.0, y: float = 0.0) -> void:
	if Gameplay.current and Gameplay.current.camera:
		var camera: Camera2D = Gameplay.current.camera
		var offset: Vector2 = Vector2(x, y)
		if char == -1:
			camera.global_position = offset
		else:
			var actor: Actor2D = Gameplay.current.get_actor_from_index(char)
			if actor:
				camera.global_position = actor.global_position
				camera.global_position += actor.camera_offset + offset

#endregion
