extends ConfirmationDialog

signal texture_creation_confirmed(type)

func _on_AddTextureLayerButton_pressed():
	popup_centered()


func _on_confirmed():
	emit_signal("texture_creation_confirmed", $TextureTypeList.get_selected_items()[0])
