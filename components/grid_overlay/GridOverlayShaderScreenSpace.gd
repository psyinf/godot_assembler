@tool
class_name GridOverlayShaderScreenSpace
extends Node2D

const GRID_SHADER = preload("res://components/grid_overlay/GridOverlayShaderScreenSpace.gdshader")
const ZERO_AXES_PASS_SCRIPT = preload("res://components/grid_overlay/ZeroGridAxesPass.gd")

@export var line_color: Color = Color(1.0, 1.0, 1.0, 0.28)
@export_range(0.1, 8.0, 0.1) var line_width_pixels: float = 0.5
@export_group("ZeroGridLines")
@export var show_zero_grid_lines: bool = false
@export var zero_x_axis_color: Color = Color(1.0, 0.25, 0.25, 0.85)
@export var zero_y_axis_color: Color = Color(0.25, 1.0, 0.25, 0.85)
@export_range(0.01, 8.0, 0.01) var zero_line_width_pixels: float = 0.2

var _tilemap_parent: TileMapLayer
var _zero_axes_pass: ZeroGridAxesPass


func _enter_tree() -> void:
	_bind_parent_tilemap()


func _ready() -> void:
	_bind_parent_tilemap()
	_ensure_shader_material()
	_sync_zero_axes_pass()
	queue_redraw()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_zero_axes_pass()
		queue_redraw()

	_update_zero_axes_pass()


func _draw() -> void:
	if not _bind_parent_tilemap():
		return

	var used_rect := _get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return

	var min_cell := used_rect.position
	var max_cell := used_rect.position + used_rect.size
	var cell_size := _get_cell_size()
	var half_cell: Vector2 = cell_size * 0.5

	var top_left: Vector2 = _map_cell_to_local(min_cell) - half_cell
	var bottom_right: Vector2 = _map_cell_to_local(max_cell) - half_cell
	var size: Vector2 = bottom_right - top_left

	if size.x <= 0.0 or size.y <= 0.0:
		return

	_ensure_shader_material()
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter("cell_size", cell_size)
	shader_material.set_shader_parameter("draw_size", size)
	shader_material.set_shader_parameter("line_thickness_pixels", line_width_pixels)
	shader_material.set_shader_parameter("line_color", line_color)

	var points := PackedVector2Array([
		top_left,
		top_left + Vector2(size.x, 0.0),
		top_left + size,
		top_left + Vector2(0.0, size.y)
	])

	var uvs := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(1.0, 0.0),
		Vector2(1.0, 1.0),
		Vector2(0.0, 1.0)
	])

	draw_polygon(points, PackedColorArray([Color.WHITE]), uvs)


func _ensure_shader_material() -> void:
	if material != null and material is ShaderMaterial and (material as ShaderMaterial).shader == GRID_SHADER:
		return

	var shader_material := ShaderMaterial.new()
	shader_material.shader = GRID_SHADER
	material = shader_material


func _sync_zero_axes_pass() -> void:
	if show_zero_grid_lines:
		if _zero_axes_pass == null or not is_instance_valid(_zero_axes_pass):
			var child := get_node_or_null("ZeroGridAxesPass")
			if child != null and child is ZeroGridAxesPass:
				_zero_axes_pass = child
			else:
				_zero_axes_pass = ZERO_AXES_PASS_SCRIPT.new()
				_zero_axes_pass.name = "ZeroGridAxesPass"
				add_child(_zero_axes_pass)

		_update_zero_axes_pass()
		return

	if _zero_axes_pass != null and is_instance_valid(_zero_axes_pass):
		_zero_axes_pass.queue_free()
		_zero_axes_pass = null


func _update_zero_axes_pass() -> void:
	if _zero_axes_pass == null or not is_instance_valid(_zero_axes_pass):
		return

	_zero_axes_pass.x_axis_color = zero_x_axis_color
	_zero_axes_pass.y_axis_color = zero_y_axis_color
	_zero_axes_pass.line_width_pixels = zero_line_width_pixels


func _bind_parent_tilemap() -> bool:
	if is_instance_valid(_tilemap_parent):
		return true

	var parent_node := get_parent()
	if parent_node == null:
		return false

	if parent_node is TileMapLayer:
		_tilemap_parent = parent_node
		return true

	_tilemap_parent = null
	return false


func _get_used_rect() -> Rect2i:
	if _tilemap_parent == null:
		return Rect2i()

	return _tilemap_parent.get_used_rect()


func _get_cell_size() -> Vector2:
	if _tilemap_parent == null:
		return Vector2.ONE

	if "tile_set" in _tilemap_parent:
		var tile_set: TileSet = _tilemap_parent.tile_set
		if tile_set != null:
			return Vector2(tile_set.tile_size)

	return Vector2.ONE


func _map_cell_to_local(cell: Vector2i) -> Vector2:
	if _tilemap_parent == null:
		return Vector2.ZERO

	return _tilemap_parent.map_to_local(cell)