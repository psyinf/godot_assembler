@tool
extends TileMapLayer

@export var area_origin: Vector2i = Vector2i.ZERO
@export var area_size: Vector2i = Vector2i(16, 32)
@export var source_id: int = 0
@export var atlas_coords: Vector2i = Vector2i.ZERO
@export var alternative_tile: int = 0


func _ready() -> void:
	call_deferred("_ensure_playable_area")


func _ensure_playable_area() -> void:
	if area_size.x <= 0 or area_size.y <= 0:
		return

	var end_x := area_origin.x + area_size.x
	var end_y := area_origin.y + area_size.y
	var changed := false

	for y in range(area_origin.y, end_y):
		for x in range(area_origin.x, end_x):
			var cell := Vector2i(x, y)
			if get_cell_source_id(cell) == -1:
				set_cell(cell, source_id, atlas_coords, alternative_tile)
				changed = true

	if changed:
		queue_redraw()
		for child in get_children():
			if child is CanvasItem:
				child.queue_redraw()