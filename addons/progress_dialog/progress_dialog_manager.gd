extends CanvasLayer

onready var dialog_container : VBoxContainer = $CenterContainer/VBoxContainer

const ProgressDialog = preload("res://addons/progress_dialog/progress_dialog.gd")

func create_task(task_name : String, action_count : int) -> ProgressDialog:
	var progress_dialog : ProgressDialog = preload("res://addons/progress_dialog/progress_dialog.tscn").instance()
	dialog_container.add_child(progress_dialog)
	progress_dialog.setup(task_name, action_count)
	progress_dialog.popup()
	return progress_dialog