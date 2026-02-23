@tool
class_name GridOverlayShader
extends Node2D

const GRID_SHADER = preload("res://components/grid_overlay/GridOverlayShader.gdshader")

@export var line_color: Color = Color(0.0, 1.0, 1.0, 0.28)
@export_range(0.5, 8.0, 0.5) var line_width: float = 1.0
@export var draw_used_rect_only: bool = true
@export var show_fallback_grid_when_empty: bool = true
@export var fallback_grid_rect: Rect2i = Rect2i(Vector2i(-8, -8), Vector2i(16, 16))

var _tilemap_parent: TileMapLayer


func _enter_tree() -> void:
	_bind_parent_tilemap()


func _ready() -> void:
	_bind_parent_tilemap()
	_ensure_shader_material()
	queue_redraw()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not _bind_parent_tilemap():
		return

	var used_rect := _get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		if show_fallback_grid_when_empty:
			used_rect = fallback_grid_rect
		else:
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
	shader_material.set_shader_parameter("line_thickness", line_width)
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

	if draw_used_rect_only:
		return _tilemap_parent.get_used_rect()

	var cells := _tilemap_parent.get_used_cells()
	if cells.is_empty():
		return Rect2i()

	var min_x := cells[0].x
	var min_y := cells[0].y
	var max_x := cells[0].x
	var max_y := cells[0].y

	for cell in cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)

	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))


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
