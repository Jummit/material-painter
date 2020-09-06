extends ConfirmationDialog

"""
A dialog for selecting a `TextureLayer` type
"""

signal texture_creation_confirmed(texture_layer)

onready var texture_type_list : ItemList = $"TextureTypeList"

const CHOICES := [
	preload("res://texture_layers/types/bitmap_texture_layer.gd"),
	preload("res://texture_layers/types/color_texture_layer.gd"),
	preload("res://texture_layers/types/scalar_texture_layer.gd")
]

func _on_AddTextureLayerButton_pressed():
	popup_centered()


func _on_confirmed():
	emit_signal("texture_creation_confirmed",
			CHOICES[texture_type_list.get_selected_items()[0]].new())


func _on_TextureTypeList_item_activated(_index : int):
	_on_confirmed()
	if not Input.is_key_pressed(KEY_CONTROL):
		hide()
