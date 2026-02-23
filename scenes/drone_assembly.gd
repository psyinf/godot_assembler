extends Node2D

const INVALID_CELL := Vector2i(2147483647, 2147483647)
const GRID_HOVER_INFO_DELAY_SEC := 0.4

var _hover_overlay: CanvasLayer
var _hover_label: Label
var _pending_hover_cell: Vector2i = INVALID_CELL
var _pending_hover_tile_type_id: StringName = StringName()
var _pending_hover_elapsed_sec: float = 0.0


func _ready() -> void:
	_create_hover_overlay()

	var palette = $TilePalettePainter
	var grid_paint_input = $GridTilePaintInput

	if palette == null or grid_paint_input == null:
		return

	palette.tile_piece_selected.connect(_on_tile_piece_selected)
	grid_paint_input.grid_tile_changed.connect(_on_grid_tile_changed)
	grid_paint_input.grid_hovered_cell_changed.connect(_on_grid_hovered_cell_changed)

	var selected = palette.get_selected_piece()
	_on_tile_piece_selected(selected.tile_type_id)


func _process(delta: float) -> void:
	if _hover_label == null:
		return

	if _pending_hover_cell != INVALID_CELL and _pending_hover_tile_type_id != StringName():
		_pending_hover_elapsed_sec += delta
		if not _hover_label.visible and _pending_hover_elapsed_sec >= GRID_HOVER_INFO_DELAY_SEC:
			_show_hover_overlay(_pending_hover_cell, _pending_hover_tile_type_id)

	if _hover_label.visible:
		_hover_label.position = get_viewport().get_mouse_position() + Vector2(16.0, 16.0)


func _on_tile_piece_selected(tile_type_id: StringName) -> void:
	$GridTilePaintInput.set_selected_tile_type(tile_type_id)


func _on_grid_tile_changed(_cell: Vector2i, _tile_type_id: StringName) -> void:
	pass


func _on_grid_hovered_cell_changed(cell: Vector2i, tile_type_id: StringName) -> void:
	$TilePalettePainter.set_hovered_cell_info(cell, tile_type_id)
	_update_hover_overlay(cell, tile_type_id)


func _create_hover_overlay() -> void:
	_hover_overlay = CanvasLayer.new()
	_hover_overlay.layer = 10
	add_child(_hover_overlay)

	_hover_label = Label.new()
	_hover_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_label.visible = false
	_hover_overlay.add_child(_hover_label)


func _update_hover_overlay(cell: Vector2i, tile_type_id: StringName) -> void:
	if _hover_label == null:
		return

	if cell == INVALID_CELL or tile_type_id == StringName():
		_pending_hover_cell = INVALID_CELL
		_pending_hover_tile_type_id = StringName()
		_pending_hover_elapsed_sec = 0.0
		_hover_label.visible = false
		return

	_pending_hover_cell = cell
	_pending_hover_tile_type_id = tile_type_id
	_pending_hover_elapsed_sec = 0.0
	_hover_label.visible = false


func _show_hover_overlay(cell: Vector2i, tile_type_id: StringName) -> void:
	if _hover_label == null:
		return

	var name := "Unknown"
	var visual := ""
	var tile_type: Dictionary = TileTypeRegistry.get_tile_type(tile_type_id)
	name = str(tile_type.get("display_name", "Unknown"))
	var atlas_coords: Vector2i = tile_type.get("atlas_coords", Vector2i.ZERO)
	visual = "\nvisual: src=%d atlas=(%d,%d) alt=%d" % [
		int(tile_type.get("source_id", -1)),
		atlas_coords.x,
		atlas_coords.y,
		int(tile_type.get("alternative_tile", 0)),
	]

	_hover_label.text = "Cell (%d,%d)\nID: %s\n%s%s" % [cell.x, cell.y, str(tile_type_id), name, visual]
	_hover_label.visible = true