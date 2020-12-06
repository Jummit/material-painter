extends PopupDialog

onready var current_action_label : Label = $MarginContainer/VBoxContainer/CurrentActionLabel
onready var progress_bar : ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
onready var task_label : Label = $MarginContainer/VBoxContainer/TaskLabel

func start_task(task_name : String, action_count : int) -> void:
	task_label.text = task_name
	progress_bar.max_value = action_count
	progress_bar.value = 0
	call_deferred("popup_centered")


func start_action(action_name : String) -> void:
	progress_bar.value += 1
	current_action_label.text = action_name


func complete_task() -> void:
	hide()
