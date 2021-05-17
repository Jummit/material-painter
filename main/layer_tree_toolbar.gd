extends HBoxContainer

func _on_Main_current_layer_material_changed(_to, _id) -> void:
	for button in get_children():
		if button is Button:
			button.disabled = false
