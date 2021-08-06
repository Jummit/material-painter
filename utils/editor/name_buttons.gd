tool
extends EditorScript

"""
A utility to name `Button` nodes after their text and class type
"""

func _run():
	for button in get_editor_interface().get_selection().get_selected_nodes():
		if button is Button:
			button.name = button.text.replace(" ", "") + button.get_class()
