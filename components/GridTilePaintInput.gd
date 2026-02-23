extends Node

signal grid_tile_changed(cell: Vector2i, tile_type_id: StringName)
signal grid_hovered_cell_changed(cell: Vector2i, tile_type_id: StringName)

const INVALID_CELL := Vector2i(2147483647, 2147483647)

@export var target_tilemap_path: NodePath = NodePath("../TileMapLayer")

var _target_tilemap: TileMapLayer
var _selected_tile_type_id: StringName = StringName()
var _cell_tile_type_ids: Dictionary = {}
var _last_hovered_cell: Vector2i = INVALID_CELL


func _ready() -> void:
	_target_tilemap = get_node_or_null(target_tilemap_path)


func _unhandled_input(event: InputEvent) -> void:
	if _target_tilemap == null:
		return

	if event is InputEventMouseMotion:
		var hovered_control := get_viewport().gui_get_hovered_control()
		if hovered_control == null:
			_emit_hovered_cell_changed()
		else:
			_emit_hover_cleared_if_needed()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hovered_control := get_viewport().gui_get_hovered_control()
		if hovered_control != null:
			return

		var world_mouse := _target_tilemap.get_global_mouse_position()
		var local_mouse := _target_tilemap.to_local(world_mouse)
		var map_cell := _target_tilemap.local_to_map(local_mouse)

		if _selected_tile_type_id == StringName():
			return

		var tile_type := TileTypeRegistry.get_tile_type(_selected_tile_type_id)
		if tile_type.is_empty():
			return

		var source_id := int(tile_type.get("source_id", -1))
		var atlas_coords: Vector2i = tile_type.get("atlas_coords", Vector2i.ZERO)
		var alternative_tile := int(tile_type.get("alternative_tile", 0))
		_target_tilemap.set_cell(map_cell, source_id, atlas_coords, alternative_tile)
		_cell_tile_type_ids[map_cell] = _selected_tile_type_id
		emit_signal("grid_tile_changed", map_cell, _selected_tile_type_id)
		_emit_hovered_cell_changed(true)
		get_viewport().set_input_as_handled()


func set_selected_tile_type(tile_type_id: StringName) -> void:
	_selected_tile_type_id = tile_type_id


func get_cell_tile_type_id(cell: Vector2i) -> StringName:
	if _cell_tile_type_ids.has(cell):
		return _cell_tile_type_ids[cell]

	if _target_tilemap == null:
		return StringName()

	var source_id := _target_tilemap.get_cell_source_id(cell)
	if source_id < 0:
		return StringName()

	var atlas_coords := _target_tilemap.get_cell_atlas_coords(cell)
	var alternative_tile := _target_tilemap.get_cell_alternative_tile(cell)
	var tile_type_id := TileTypeRegistry.get_or_create_type_id(source_id, atlas_coords, alternative_tile)
	_cell_tile_type_ids[cell] = tile_type_id
	return tile_type_id

	return StringName()


func _emit_hovered_cell_changed(force_emit: bool = false) -> void:
	var world_mouse := _target_tilemap.get_global_mouse_position()
	var local_mouse := _target_tilemap.to_local(world_mouse)
	var map_cell := _target_tilemap.local_to_map(local_mouse)
	if not force_emit and map_cell == _last_hovered_cell:
		return

	_last_hovered_cell = map_cell
	var hovered_tile_type_id := get_cell_tile_type_id(map_cell)
	emit_signal("grid_hovered_cell_changed", map_cell, hovered_tile_type_id)


func _emit_hover_cleared_if_needed() -> void:
	if _last_hovered_cell == INVALID_CELL:
		return

	_last_hovered_cell = INVALID_CELL
	emit_signal("grid_hovered_cell_changed", INVALID_CELL, StringName())