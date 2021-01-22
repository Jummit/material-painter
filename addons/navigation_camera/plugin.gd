tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("NavigationCamera", "Camera", load("res://addons/navigation_camera/navigation_camera.gd"), load("res://addons/navigation_camera/navigation_camera_icon.svg"))


func _exit_tree():
	remove_custom_type("NavigationCamera")
