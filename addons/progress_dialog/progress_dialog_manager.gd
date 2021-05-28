extends CanvasLayer

"""
A utility for showing a list of `ProgressDialogs` simultaniously
"""

var theme : Theme setget set_theme

const ProgressDialog = preload("res://addons/progress_dialog/progress_dialog.gd")

onready var dialog_container : VBoxContainer = $CenterContainer/VBoxContainer

func create_task(task_name : String, action_count : int) -> ProgressDialog:
	var progress_dialog : ProgressDialog = preload(\
			"res://addons/progress_dialog/progress_dialog.tscn").instance() as ProgressDialog
	dialog_container.add_child(progress_dialog)
# warning-ignore:unsafe_method_access
	progress_dialog.setup(task_name, action_count)
	dialog_container.queue_sort()
	return progress_dialog


func set_theme(to) -> void:
	theme = to
	dialog_container.theme = to
