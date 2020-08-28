extends ConfirmationDialog

const TextureLayerTree = preload("res://texture_layer_tree.gd")

signal texture_creation_confirmed(type)

func _on_AddTextureLayerButton_pressed():
	popup_centered()


func _on_confirmed():
	var texture_layer : TextureLayerTree.TextureLayer
	match $TextureTypeList.get_selected_items()[0]:
		0:
			texture_layer = TextureLayerTree.BitmapTextureLayer.new("New Bitmap Texture")
		1:
			texture_layer = TextureLayerTree.ColorTextureLayer.new("New Paint Texture")
		2:
			texture_layer = TextureLayerTree.NoiseTextureLayer.new("New Noise Texture")
		3:
			texture_layer = TextureLayerTree.ColorTextureLayer.new("New Color Texture")
	emit_signal("texture_creation_confirmed", texture_layer)


func _on_TextureTypeList_item_activated(_index : int):
	_on_confirmed()
	hide()
