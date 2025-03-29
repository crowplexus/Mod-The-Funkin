## Object used during gameplay to display a background.
class_name FunkinStage2D
extends Node2D

## Camera attached to the stage.
@export var camera: Camera2D = null
## Default Zoom Factor for the camera.
@export var camera_zoom: Vector2 = Vector2.ONE
## Default Drag Speed for the camera.
@export var camera_speed_drag: float = 1.0
## Default Rotation Speed for the camera.
@export var camera_speed_rota: float = 1.0
## Camera will zoom automatically.
@export var auto_zoom: bool = true
## Zoom Interval (in beats).
@export var zoom_interval: float = 4.0
## Zoom Intensity (in beats).
@export var zoom_intensity: float = 0.020 # 20%

func _ready() -> void:
	initialize_camera_2d()
	Conductor.on_beat_hit.connect(bump_camera)

func _process(delta: float) -> void:
	reset_camera_bump(delta)

func _exit_tree() -> void:
	Conductor.on_beat_hit.disconnect(bump_camera)


func initialize_camera_2d() -> void:
	if not camera:
		return
	camera.zoom = camera_zoom
	camera.position_smoothing_speed = camera_speed_drag
	camera.rotation_smoothing_speed = camera_speed_rota
	bump_camera(2.0) # forced


func reset_camera_bump(_delta: float) -> void:
	if not camera or not auto_zoom: return
	if camera.zoom != camera_zoom:
		camera.zoom = Global.lerpv2(camera.zoom, camera_zoom, 0.05) # TODO: use exp()


func bump_camera(beat: float) -> void:
	if not camera or not auto_zoom or int(beat) < 0: return
	#var digits: int = str(zoom_interval).split("").size()
	if int(beat * 100) % int(zoom_interval * 100):
		camera.zoom += Vector2(zoom_intensity, zoom_intensity)
