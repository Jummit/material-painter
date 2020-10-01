extends Camera

"""
A camera that can be rotated and panned around a center using the mouse
"""

var sensitity := 0.01
var zoom_sensitity := 0.3

onready var horizontal_camera_socket : Spatial = get_parent()
onready var vertical_camera_socket : Spatial = get_parent().get_parent()

func _input(event : InputEvent) -> void:
	if event is InputEventMouseButton and (event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN) and get_viewport().get_visible_rect().has_point(event.position):
		translation.z += (1.0 if event.button_index == BUTTON_WHEEL_DOWN else -1.0) * zoom_sensitity
		translation.z = clamp(translation.z, .4, 20.0)
	if event is InputEventMouseMotion and event.button_mask == BUTTON_MASK_MIDDLE and get_viewport().get_visible_rect().has_point(event.position):
		if event.shift:
			vertical_camera_socket.translate_object_local(Vector3.LEFT * event.relative.x * sensitity)
			vertical_camera_socket.global_transform.origin += global_transform.basis.y * event.relative.y * sensitity
		else:
			horizontal_camera_socket.rotate_x(-event.relative.y * sensitity)
			vertical_camera_socket.rotate_y(-event.relative.x * sensitity)
			horizontal_camera_socket.rotation_degrees.x = clamp(horizontal_camera_socket.rotation_degrees.x, -90.0, 90.0)
