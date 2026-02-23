extends CanvasLayer

@export var target_tilemap_path: NodePath = NodePath("../TileMapLayer")
@export var palette_grid_path: NodePath = NodePath("PaletteRoot/Panel/Margin/Scroll/PieceGrid")
@export var source_id: int = 0
@export_range(24.0, 256.0, 1.0) var swatch_size: float = 56.0

var _target_tilemap: TileMapLayer
var _palette_grid: GridContainer
var _selected_atlas_coords: Vector2i = Vector2i.ZERO
var _selected_alternative_tile: int = 0
var _selected_button: TextureButton


func _ready() -> void:
	_target_tilemap = get_node_or_null(target_tilemap_path)
	_palette_grid = get_node_or_null(palette_grid_path)
	if _palette_grid == null:
		_palette_grid = find_child("PieceGrid", true, false) as GridContainer

	if _target_tilemap == null or _palette_grid == null:
		return

	_build_palette()


func _input(event: InputEvent) -> void:
	if _target_tilemap == null:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hovered_control := get_viewport().gui_get_hovered_control()
		if hovered_control != null:
			return

		var world_mouse := _target_tilemap.get_global_mouse_position()
		var local_mouse := _target_tilemap.to_local(world_mouse)
		var map_cell := _target_tilemap.local_to_map(local_mouse)
		_target_tilemap.set_cell(map_cell, source_id, _selected_atlas_coords, _selected_alternative_tile)
		get_viewport().set_input_as_handled()


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

	button.tooltip_text = "(%d, %d)" % [atlas_coords.x, atlas_coords.y]
	button.pressed.connect(_on_piece_pressed.bind(button, atlas_coords))
	_palette_grid.add_child(button)

	if _selected_button == null:
		_on_piece_pressed(button, atlas_coords)


func _on_piece_pressed(button: TextureButton, atlas_coords: Vector2i) -> void:
	if _selected_button != null:
		_selected_button.modulate = Color(1.0, 1.0, 1.0, 1.0)

	_selected_button = button
	_selected_button.modulate = Color(0.65, 1.0, 0.65, 1.0)
	_selected_atlas_coords = atlas_coords
	_selected_alternative_tile = 0