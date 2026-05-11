extends Control

signal moved(direction: Vector2)

var touch_index: int = -1
var base_radius: float = 75.0   # Mitad del ancho del Background

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1 and _is_point_in_base(event.position):
			touch_index = event.index
			_update_knob(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			$Knob.position = Vector2.ZERO
			moved.emit(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == touch_index:
		_update_knob(event.position)

func _is_point_in_base(point: Vector2) -> bool:
	var base_center = $Background.global_position + $Background.size / 2
	return point.distance_to(base_center) <= base_radius

func _update_knob(touch_pos: Vector2):
	var base_center = $Background.global_position + $Background.size / 2
	var local_vec = touch_pos - base_center
	var distance = min(local_vec.length(), base_radius)
	var direction = local_vec.normalized() * (distance / base_radius)
	$Knob.position = direction * base_radius
	moved.emit(direction)
