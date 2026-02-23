extends Node

var _tile_types: Dictionary = {}
var _visual_to_id: Dictionary = {}


func get_or_create_type_id(source_id: int, atlas_coords: Vector2i, alternative_tile: int = 0) -> StringName:
	var visual_key := _make_visual_key(source_id, atlas_coords, alternative_tile)
	if _visual_to_id.has(visual_key):
		return _visual_to_id[visual_key]

	var tile_type_id := StringName("tile_%d_%d_%d_%d" % [source_id, atlas_coords.x, atlas_coords.y, alternative_tile])
	var display_name := "Tile (%d, %d)" % [atlas_coords.x, atlas_coords.y]

	var tile_data := {
		"id": tile_type_id,
		"resource_id": tile_type_id,
		"display_name": display_name,
		"description": "Prototype tile type for atlas (%d, %d)" % [atlas_coords.x, atlas_coords.y],
		"source_id": source_id,
		"atlas_coords": atlas_coords,
		"alternative_tile": alternative_tile,
	}

	_tile_types[tile_type_id] = tile_data
	_visual_to_id[visual_key] = tile_type_id
	return tile_type_id


func get_tile_type(tile_type_id: StringName) -> Dictionary:
	if _tile_types.has(tile_type_id):
		return _tile_types[tile_type_id]
	return {}


func find_tile_type_id(source_id: int, atlas_coords: Vector2i, alternative_tile: int = 0) -> StringName:
	var visual_key := _make_visual_key(source_id, atlas_coords, alternative_tile)
	if _visual_to_id.has(visual_key):
		return _visual_to_id[visual_key]
	return StringName()


func _make_visual_key(source_id: int, atlas_coords: Vector2i, alternative_tile: int) -> String:
	return "%d:%d:%d:%d" % [source_id, atlas_coords.x, atlas_coords.y, alternative_tile]
