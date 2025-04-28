## Object used during gameplay to display a background.
class_name FunkinStage2D extends Node2D

@export var camera: Camera2D = null ## Camera attached to the stage.
@export var auto_zoom: bool = true ## If the camera should zoom automatically.
@export var zoom_interval: float = 4.0 ## Zoom Interval (in beats).
@export var zoom_intensity: float = 0.020 ## Zoom Intensity (defaults to 20% or 0.020).
var camera_zoom: Vector2 = Vector2.ONE

func _ready() -> void:
	initialize_camera_2d()
	Conductor.on_beat_hit.connect(on_beat_hit)

func _process(delta: float) -> void:
	reset_camera_bump(delta)

func _exit_tree() -> void:
	if Conductor.on_beat_hit.is_connected(on_beat_hit):
		Conductor.on_beat_hit.disconnect(on_beat_hit)

func initialize_camera_2d() -> void:
	if camera:
		camera_zoom = camera.zoom
		bump_camera(2.0) # forced

func reset_camera_bump(_delta: float) -> void:
	if not camera or not auto_zoom: return
	if camera.zoom != camera_zoom:
		camera.zoom = lerp(camera.zoom, camera_zoom, _delta * 5.0)

func on_beat_hit(beat: float) -> void:
	if camera and auto_zoom: bump_camera(beat)

func bump_camera(beat: float) -> void:
	if int(beat) < 0: return
	#var digits: int = str(zoom_interval).split("").size()
	if fmod(snappedf(beat, 0.01), zoom_interval) <= zoom_interval:
		camera.zoom += Vector2(zoom_intensity, zoom_intensity)
