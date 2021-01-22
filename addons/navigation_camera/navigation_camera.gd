tool
extends Camera

"""
A camera that can be rotated and panned around a center using the mouse
"""

export(float, 0.0, 0.1) var rotation_sensitity := 0.01
export(float, 0.0, 1.0) var moving_sensitity := 0.2
export(float, 0.0, 1.0) var zoom_sensitity := 0.3
export var pan_only := false

export var focus_point := Vector3.ZERO

var horizontal_rotation := 0.0
var vertical_rotation := 0.0
var zoom := 0.0

func _ready() -> void:
	zoom = -translation.z


func _input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			zoom += zoom_sensitity
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom -= zoom_sensitity
		transform = _generate_transform(horizontal_rotation,
				vertical_rotation, zoom, focus_point)
	if event is InputEventMouseMotion and event.button_mask == BUTTON_MASK_MIDDLE:
		if event.shift or pan_only:
			focus_point -= transform.basis.x * event.relative.x * moving_sensitity / 100 * -zoom
			focus_point += transform.basis.y * event.relative.y * moving_sensitity / 100  * -zoom
		else:
			vertical_rotation -= event.relative.x * rotation_sensitity
			horizontal_rotation -= event.relative.y * rotation_sensitity
		transform = _generate_transform(horizontal_rotation,
				vertical_rotation, zoom, focus_point)


static func _generate_transform(_horizontal_rotation : float,
		_vertical_rotation : float, _zoom : float,
		_focus_point : Vector3) -> Transform:
	var transform := Transform.IDENTITY\
			.translated(Vector3.FORWARD * _zoom)\
			.rotated(Vector3.RIGHT, _horizontal_rotation)\
			.rotated(Vector3.UP, _vertical_rotation)\
	# don't use translated because it is local
	transform.origin += _focus_point
	return transform
