@tool
extends StaticBody3D

const GRASS_MESH_HIGH := preload("uid://cjjcs3i3mtfp0")
const GRASS_MESH_LOW := preload("uid://d2o2w4alobn3i")
const GRASS_MAT := preload("uid://y6fsll8cbpbu")
const HEIGHTMAP := preload("uid://cu778cjhw0raj")

const TILE_SIZE := 5.0
const MAP_RADIUS := 200.0
const HEIGHTMAP_SCALE := 5.0

var grass_multimeshes : Array[Array] = []

@onready var density_modifier := 0.8 if Engine.is_editor_hint() else 1.0
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

func _init() -> void:
	RenderingServer.global_shader_parameter_set('heightmap', HEIGHTMAP)
	RenderingServer.global_shader_parameter_set('heightmap_scale', HEIGHTMAP_SCALE)

func _ready() -> void:
	RenderingServer.viewport_set_measure_render_time(get_tree().root.get_viewport_rid(), true)
	_setup_heightmap_collision()
	_setup_grass_instances()
	_generate_grass_multimeshes()

func apply_wind_speed(value: float) -> void:
	GRASS_MAT.set_shader_parameter('wind_speed', (value + 0.1)*0.91)

func apply_clumping_factor(value: float) -> void:
	GRASS_MAT.set_shader_parameter('clumping_factor', value)

func apply_density(value: float) -> void:
	density_modifier = value
	_generate_grass_multimeshes()

## Creates a HeightMapShape3D from the provided NoiseTexture2D
func _setup_heightmap_collision() -> void:
	var heightmap := HEIGHTMAP.noise.get_image(512, 512)
	var dims := Vector2i(heightmap.get_height(), heightmap.get_width())
	var map_data : PackedFloat32Array
	for j in dims.x:
		for i in dims.y:
			map_data.push_back((heightmap.get_pixel(i, j).r - 0.5)*HEIGHTMAP_SCALE)
	
	var heightmap_shape := HeightMapShape3D.new()
	heightmap_shape.map_width = dims.x
	heightmap_shape.map_depth = dims.y
	heightmap_shape.map_data = map_data
	collision_shape_3d.shape = heightmap_shape

## Creates initial tiled multimesh instances.
func _setup_grass_instances() -> void:
	for i in range(-MAP_RADIUS, MAP_RADIUS, TILE_SIZE):
		for j in range(-MAP_RADIUS, MAP_RADIUS, TILE_SIZE):
			var instance := MultiMeshInstance3D.new()
			#instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if should_render_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			instance.material_override = GRASS_MAT
			instance.position = Vector3(i, 0.0, j)
			instance.extra_cull_margin = 1.0
			add_child(instance)
			
			grass_multimeshes.append([instance, instance.position])

## Generates multimeshes for previously created multimesh instances with LOD based
## on distance to origin.
func _generate_grass_multimeshes() -> void:
	var multimesh_lods : Array[MultiMesh] = [
		create_grass_multimesh(1.0*density_modifier, TILE_SIZE, GRASS_MESH_HIGH),
		create_grass_multimesh(0.5*density_modifier, TILE_SIZE, GRASS_MESH_HIGH),
		create_grass_multimesh(0.25*density_modifier, TILE_SIZE, GRASS_MESH_LOW),
		create_grass_multimesh(0.1*density_modifier, TILE_SIZE, GRASS_MESH_LOW),
		create_grass_multimesh(0.02*(1.0 if density_modifier != 0.0 else 0.0), TILE_SIZE, GRASS_MESH_LOW),
	]
	for data in grass_multimeshes:
		var distance = data[1].length() # Distance from center tile
		if distance > MAP_RADIUS: continue
		if distance < 12.0:    data[0].multimesh = multimesh_lods[0]
		elif distance < 40.0:  data[0].multimesh = multimesh_lods[1]
		elif distance < 70.0:  data[0].multimesh = multimesh_lods[2]
		elif distance < 100.0: data[0].multimesh = multimesh_lods[3]
		else:                  data[0].multimesh = multimesh_lods[4]

func create_grass_multimesh(density : float, tile_size : float, mesh : Mesh) -> MultiMesh:
	var row_size = ceil(tile_size*lerpf(0.0, 10.0, density));
	var multimesh := MultiMesh.new()
	multimesh.mesh = mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = row_size*row_size

	var jitter_offset := tile_size/float(row_size) * 0.5 * 0.9
	for i in row_size:
		for j in row_size:
			var grass_position := Vector3(i/float(row_size) - 0.5, 0, j/float(row_size) - 0.5) * tile_size
			var grass_offset := Vector3(randf_range(-jitter_offset, jitter_offset), 0, randf_range(-jitter_offset, jitter_offset))
			multimesh.set_instance_transform(i + j*row_size, Transform3D(Basis(), grass_position + grass_offset))
	return multimesh
