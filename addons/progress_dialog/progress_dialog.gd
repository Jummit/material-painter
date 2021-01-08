extends Panel

"""
A panel which shows the progress of a task
"""

onready var current_action_label : Label = $MarginContainer/VBoxContainer/CurrentActionLabel
onready var progress_bar : ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
onready var task_label : Label = $MarginContainer/VBoxContainer/TaskLabel

func setup(task_name : String, action_count : int) -> void:
	task_label.text = task_name
	progress_bar.max_value = action_count
	progress_bar.value = 0


func set_action(action_name : String, value := -1) -> void:
	progress_bar.value += 1
	if value != -1:
		progress_bar.value = value
	current_action_label.text = action_name


func complete_task() -> void:
	queue_free()
