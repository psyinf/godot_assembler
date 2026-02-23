extends Camera2D

@export_range(50.0, 3000.0, 10.0) var move_speed: float = 600.0
@export_group("Zoom")
@export_range(0.01, 1.0, 0.01) var zoom_step: float = 0.1
@export_range(0.01, 10.0, 0.1) var min_zoom: float = 0.5
@export_range(0.01, 10.0, 0.1) var max_zoom: float = 3.0
@export_range(0.1, 10.0, 0.1) var initial_zoom: float = 0.5

var _is_dragging: bool = false
var _drag_anchor_world: Vector2 = Vector2.ZERO


func _ready() -> void:
	_set_zoom(initial_zoom)


func _process(delta: float) -> void:
	var input_direction := Vector2.ZERO

	if Input.is_physical_key_pressed(KEY_A):
		input_direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input_direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_direction.y += 1.0

	if input_direction == Vector2.ZERO:
		return

	position += input_direction.normalized() * move_speed * delta


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = event.pressed
			if _is_dragging:
				_drag_anchor_world = get_global_mouse_position()
			return

		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_apply_zoom(zoom_step)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_apply_zoom(-zoom_step)
		return

	if event is InputEventMouseMotion and _is_dragging:
		var mouse_world := get_global_mouse_position()
		global_position += _drag_anchor_world - mouse_world


func _apply_zoom(zoom_delta: float) -> void:
	_set_zoom(zoom.x + zoom_delta)


func _set_zoom(value: float) -> void:
	var next_zoom := clampf(value, min_zoom, max_zoom)
	zoom = Vector2.ONE * next_zoom
