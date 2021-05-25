extends Button

"""
A `Button` to select a path to be used in a `PropertyPanel`

Right-clicking clears the path.
"""

signal changed

var path := "" setget set_path

onready var file_dialog : FileDialog = $FileDialog

func _gui_input(event : InputEvent) -> void:
	var button_ev = event as InputEventMouseButton
	if button_ev and button_ev.pressed and button_ev.button_index == BUTTON_RIGHT:
			set_path("")
			emit_signal("changed")


func set_path(to : String):
	path = to
	text = path.get_file()
	hint_tooltip = path


func _on_FileDialog_file_selected(selected_path : String):
	set_path(selected_path)
	emit_signal("changed")


func _pressed():
	file_dialog.popup_centered()
