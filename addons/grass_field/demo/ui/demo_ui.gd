extends Control

## Controls demo user interface and applied changes to respective water parameters.

@onready var grass: StaticBody3D = $"../Grass"
@onready var environment: WorldEnvironment = $"../Environment"

@onready var demo_ui: Control = $"."
@onready var ui_toggle: CheckBox = $UIToggle
@onready var fps_label: Label = $Grass/VBoxContainer/CameraContainer/FPS
@onready var camera := get_viewport().get_camera_3d()
@onready var camera_fov: HSlider = $Grass/VBoxContainer/CameraContainer/CameraFOV
@onready var camera_position: Label = $Grass/VBoxContainer/CameraContainer/CameraPosition


func _ready() -> void:
	update_frame_counter()
	update_camera_labels()

func _process(delta : float) -> void:
	update_frame_counter()
	update_camera_labels()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&'toggle_fullscreen'):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED else DisplayServer.WINDOW_MODE_WINDOWED)
	elif event.is_action_pressed(&'ui_cancel'):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if (event.is_action_pressed(&'toggle_ui')):
		demo_ui.visible = !demo_ui.visible


func update_frame_counter() -> void:
	var fps := Engine.get_frames_per_second()
	fps_label.text = str('%.0f' % fps, " ", '(%.2fms)' % (1.0 / fps*1e3))

func update_camera_labels() -> void:
	if (camera == null):
		printerr("No valid camera found.")
		return
	camera_fov.value = camera.fov
	camera_position.text = '%+.2v' % camera.global_position


func _on_render_fog_toggled(toggled_on: bool) -> void:
	environment.environment.volumetric_fog_enabled = toggled_on

func _on_render_shadows_toggled(toggled_on: bool) -> void:
	for data in grass.grass_multimeshes:
		data[0].cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if toggled_on else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _on_camera_fov_value_changed(value: float) -> void:
	if (camera != null): camera.fov = camera_fov.value

func _on_wind_speed_value_changed(value: float) -> void:
	grass.apply_wind_speed(value)

func _on_grass_density_value_changed(value: float) -> void:
	grass.apply_density(value)

func _on_clumping_factor_value_changed(value: float) -> void:
	grass.apply_clumping_factor(value)
