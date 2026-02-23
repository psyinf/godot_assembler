@tool
class_name ZeroGridAxesPass
extends Node2D

const AXES_SHADER = preload("res://components/grid_overlay/ZeroGridAxesPass.gdshader")

@export var x_axis_color: Color = Color(1.0, 0.25, 0.25, 0.85)
@export var y_axis_color: Color = Color(0.25, 1.0, 0.25, 0.85)
@export_range(0.1, 8.0, 0.1) var line_width_pixels: float = 0.2


func _ready() -> void:
	_ensure_material()
	z_as_relative = false
	z_index = 1000
	set_process(true)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var zoom := Vector2(max(camera.zoom.x, 0.0001), max(camera.zoom.y, 0.0001))
	var half_size_world := (viewport_size / zoom) * 0.5
	var top_left := camera.global_position - half_size_world
	var world_size := half_size_world * 2.0
	var origin_screen_pos := get_viewport().get_canvas_transform() * Vector2.ZERO

	_ensure_material()
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter("viewport_size", viewport_size)
	shader_material.set_shader_parameter("origin_screen_pos", origin_screen_pos)
	shader_material.set_shader_parameter("line_width_pixels", line_width_pixels)
	shader_material.set_shader_parameter("x_axis_color", x_axis_color)
	shader_material.set_shader_parameter("y_axis_color", y_axis_color)

	var points := PackedVector2Array([
		top_left,
		top_left + Vector2(world_size.x, 0.0),
		top_left + world_size,
		top_left + Vector2(0.0, world_size.y)
	])

	var uvs := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(1.0, 0.0),
		Vector2(1.0, 1.0),
		Vector2(0.0, 1.0)
	])

	draw_polygon(points, PackedColorArray([Color.WHITE]), uvs)


func _ensure_material() -> void:
	if material != null and material is ShaderMaterial and (material as ShaderMaterial).shader == AXES_SHADER:
		return

	var shader_material := ShaderMaterial.new()
	shader_material.shader = AXES_SHADER
	material = shader_material
