tool
extends EditorScript

func _run():
	for button in get_editor_interface().get_selection().get_selected_nodes():
		button = button as Button
		button.name = button.text + button.get_class()
