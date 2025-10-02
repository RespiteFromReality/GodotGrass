@tool
extends Node3D

## Controls screen size and position, sounds effects and applies player position to grass shader.

var tile_id := Vector3.ZERO
var previous_tile_id := Vector3.ZERO

@onready var grass: StaticBody3D = $Grass
@onready var player: CharacterBody3D = $Player

@onready var wind_speed: float = grass.GRASS_MAT.get_shader_parameter('wind_speed')

@onready var grass_audio_player: AudioStreamPlayer = $GrassAudioPlayer
@onready var wind_audio_player: AudioStreamPlayer = $WindAudioPlayer
@onready var insect_audio_player: AudioStreamPlayer = $InsectAudioPlayer

func _init() -> void:
	if DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	var monitor_size : Vector2 = DisplayServer.screen_get_size()
	var monitor_origin : Vector2 = DisplayServer.screen_get_position()
	var window_size : Vector2 = monitor_size * 0.75
	var centered_offset : Vector2 = (monitor_size - window_size) / 2
	var window_position : Vector2 = monitor_origin + centered_offset
	DisplayServer.window_set_position(window_position)
	DisplayServer.window_set_size(window_size)

func _process(_delta) -> void:
	if (player == null):
		printerr("No valid player found.")
		return;
	
	# Modulate sfx based on wind speed.
	wind_audio_player.pitch_scale = lerpf(0.8, 2.0, wind_speed / 5.0)
	wind_audio_player.volume_db = lerpf(-10.0, 5.0, min(wind_speed, 1.0))
	grass_audio_player.volume_db = lerpf(-30.0, -18.5, wind_speed / 5.0)
	insect_audio_player.volume_db = lerpf(-30.0, -80.0, wind_speed / 5.0)

func _physics_process(delta: float) -> void:
	# Correct LOD by repositioning tiles when the player moves into a new tile.
	var lod_target = EditorInterface.get_editor_viewport_3d(0).get_camera_3d() if Engine.is_editor_hint() else player
	if (lod_target == null): 
		printerr("LOD target is missing or has broken reference. Cannot adjust LOD to player movement.")
		return
	
	var tile_id : Vector3 = ((lod_target.global_position + Vector3.ONE*grass.TILE_SIZE*0.5) / grass.TILE_SIZE * Vector3(1,0,1)).floor()
	if tile_id != previous_tile_id:
		for data in grass.grass_multimeshes:
			data[0].global_position = data[1] + Vector3(1,0,1)*grass.TILE_SIZE*tile_id
	previous_tile_id = tile_id
	
	# Adjusts grass to player movement.
	RenderingServer.global_shader_parameter_set('player_position', lod_target.global_position)
