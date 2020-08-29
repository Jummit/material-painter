extends Camera

onready var horizontal_camera_socket : Spatial = get_parent()
onready var vertical_camera_socket : Spatial = get_parent().get_parent()

var sensitity := 0.01

func _input(event : InputEvent):
	if event is InputEventMouseMotion and event.button_mask == BUTTON_MASK_MIDDLE:
		horizontal_camera_socket.rotate_x(-event.relative.y * sensitity)
		vertical_camera_socket.rotate_y(-event.relative.x * sensitity)
