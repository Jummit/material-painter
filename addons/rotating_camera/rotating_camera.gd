extends Camera

"""
A camera that can be rotated around a center using the mouse
"""

var sensitity := 0.01
var zoom_sensitity := 0.3

onready var horizontal_camera_socket : Spatial = get_parent()
onready var vertical_camera_socket : Spatial = get_parent().get_parent()

func _input(event : InputEvent) -> void:
	if event is InputEventMouseButton and (event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN):
		translation.z += (1.0 if event.button_index == BUTTON_WHEEL_DOWN else -1.0) * zoom_sensitity
	if event is InputEventMouseMotion and event.button_mask == BUTTON_MASK_MIDDLE:
		if event.shift:
			vertical_camera_socket.translate_object_local(Vector3.LEFT * event.relative.x * sensitity)
			vertical_camera_socket.global_transform.origin += global_transform.basis.y * event.relative.y * sensitity
		else:
			horizontal_camera_socket.rotate_x(-event.relative.y * sensitity)
			vertical_camera_socket.rotate_y(-event.relative.x * sensitity)
