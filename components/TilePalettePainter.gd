extends CanvasLayer

signal tile_piece_selected(tile_type_id: StringName)

@export var target_tilemap_path: NodePath = NodePath("../TileMapLayer")
@export var palette_grid_path: NodePath = NodePath("PaletteRoot/Panel/Margin/Scroll/PieceGrid")
@export var selected_name_label_path: NodePath = NodePath("PaletteRoot/SelectedInfo/InfoMargin/InfoVBox/SelectedNameValue")
@export var selected_id_label_path: NodePath = NodePath("PaletteRoot/SelectedInfo/InfoMargin/InfoVBox/SelectedIdValue")
@export var selected_visual_label_path: NodePath = NodePath("PaletteRoot/SelectedInfo/InfoMargin/InfoVBox/SelectedVisualValue")
@export var hovered_cell_label_path: NodePath = NodePath("PaletteRoot/SelectedInfo/InfoMargin/InfoVBox/HoveredCellValue")
@export var hovered_id_label_path: NodePath = NodePath("PaletteRoot/SelectedInfo/InfoMargin/InfoVBox/HoveredIdValue")
@export var hovered_name_label_path: NodePath = NodePath("PaletteRoot/SelectedInfo/InfoMargin/InfoVBox/HoveredNameValue")
@export var source_id: int = 0
@export_range(24.0, 256.0, 1.0) var swatch_size: float = 56.0

var _target_tilemap: TileMapLayer
var _palette_grid: GridContainer
var _selected_name_label: Label
var _selected_id_label: Label
var _selected_visual_label: Label
var _hovered_cell_label: Label
var _hovered_id_label: Label
var _hovered_name_label: Label
var _selected_tile_type_id: StringName = StringName()
var _selected_button: TextureButton


func _ready() -> void:
	_target_tilemap = get_node_or_null(target_tilemap_path)
	_palette_grid = get_node_or_null(palette_grid_path)
	_selected_name_label = get_node_or_null(selected_name_label_path)
	_selected_id_label = get_node_or_null(selected_id_label_path)
	_selected_visual_label = get_node_or_null(selected_visual_label_path)
	_hovered_cell_label = get_node_or_null(hovered_cell_label_path)
	_hovered_id_label = get_node_or_null(hovered_id_label_path)
	_hovered_name_label = get_node_or_null(hovered_name_label_path)
	if _palette_grid == null:
		_palette_grid = find_child("PieceGrid", true, false) as GridContainer

	if _target_tilemap == null or _palette_grid == null:
		return

	_build_palette()


func _build_palette() -> void:
	for child in _palette_grid.get_children():
		child.queue_free()

	var tile_set := _target_tilemap.tile_set
	if tile_set == null:
		return

	if not tile_set.has_source(source_id):
		return

	var source := tile_set.get_source(source_id)
	if source == null:
		return

	var region_size := tile_set.tile_size
	if source.has_method("get_tiles_count") and source.has_method("get_tile_id"):
		var count: int = source.get_tiles_count()
		for i in range(count):
			var atlas_coords: Vector2i = source.get_tile_id(i)
			_add_piece_button(source, region_size, atlas_coords)


func _add_piece_button(source: TileSetSource, region_size: Vector2i, atlas_coords: Vector2i) -> void:
	var tile_type_id := TileTypeRegistry.get_or_create_type_id(source_id, atlas_coords, 0)
	var button := TextureButton.new()
	button.custom_minimum_size = Vector2(swatch_size, swatch_size)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	if source is TileSetAtlasSource:
		var atlas_source := source as TileSetAtlasSource
		var preview_texture := AtlasTexture.new()
		preview_texture.atlas = atlas_source.texture
		preview_texture.region = Rect2i(atlas_coords * region_size, region_size)
		button.texture_normal = preview_texture

	button.tooltip_text = "%s | (%d, %d)" % [tile_type_id, atlas_coords.x, atlas_coords.y]
	button.pressed.connect(_on_piece_pressed.bind(button, tile_type_id))
	_palette_grid.add_child(button)

	if _selected_button == null:
		_on_piece_pressed(button, tile_type_id)


func _on_piece_pressed(button: TextureButton, tile_type_id: StringName) -> void:
	if _selected_button != null:
		_selected_button.modulate = Color(1.0, 1.0, 1.0, 1.0)

	_selected_button = button
	_selected_button.modulate = Color(0.65, 1.0, 0.65, 1.0)
	_selected_tile_type_id = tile_type_id
	_update_selected_info()
	emit_signal("tile_piece_selected", _selected_tile_type_id)


func _update_selected_info() -> void:
	var tile_type := TileTypeRegistry.get_tile_type(_selected_tile_type_id)
	if tile_type.is_empty():
		return

	if _selected_name_label != null:
		_selected_name_label.text = str(tile_type.get("display_name", "-"))
	if _selected_id_label != null:
		_selected_id_label.text = str(tile_type.get("resource_id", "-"))
	if _selected_visual_label != null:
		var atlas_coords: Vector2i = tile_type.get("atlas_coords", Vector2i.ZERO)
		_selected_visual_label.text = "source=%d atlas=(%d,%d) alt=%d" % [
			int(tile_type.get("source_id", -1)),
			atlas_coords.x,
			atlas_coords.y,
			int(tile_type.get("alternative_tile", 0)),
		]


func get_selected_piece() -> Dictionary:
	return {
		"tile_type_id": _selected_tile_type_id,
	}


func set_hovered_cell_info(cell: Vector2i, tile_type_id: StringName) -> void:
	if tile_type_id == StringName():
		if _hovered_cell_label != null:
			_hovered_cell_label.text = ""
		if _hovered_id_label != null:
			_hovered_id_label.text = ""
		if _hovered_name_label != null:
			_hovered_name_label.text = ""
		return

	if _hovered_cell_label != null:
		_hovered_cell_label.text = "(%d, %d)" % [cell.x, cell.y]

	if _hovered_id_label != null:
		_hovered_id_label.text = str(tile_type_id)

	var tile_type: Dictionary = TileTypeRegistry.get_tile_type(tile_type_id)
	if _hovered_name_label != null:
		_hovered_name_label.text = str(tile_type.get("display_name", "Unknown"))