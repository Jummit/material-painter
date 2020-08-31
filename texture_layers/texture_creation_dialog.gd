extends ConfirmationDialog

const TextureLayer = preload("res://texture_layers/texture_layer.gd")
const BitmapTextureLayer = preload("res://texture_layers/types/bitmap_texture_layer.gd")
const ColorTextureLayer = preload("res://texture_layers/types/color_texture_layer.gd")
const NoiseTextureLayer = preload("res://texture_layers/types/noise_texture_layer.gd")
const PaintTextureLayer = preload("res://texture_layers/types/paint_texture_layer.gd")
const ScalarTextureLayer = preload("res://texture_layers/types/scalar_texture_layer.gd")

signal texture_creation_confirmed(type)

func _on_AddTextureLayerButton_pressed():
	popup_centered()


func _on_confirmed():
	var texture_layer : TextureLayer
	match $TextureTypeList.get_selected_items()[0]:
		0:
			texture_layer = BitmapTextureLayer.new()
		1:
			texture_layer = PaintTextureLayer.new()
		2:
			texture_layer = NoiseTextureLayer.new()
		3:
			texture_layer = ColorTextureLayer.new()
		4:
			texture_layer = ScalarTextureLayer.new()
	emit_signal("texture_creation_confirmed", texture_layer)


func _on_TextureTypeList_item_activated(_index : int):
	_on_confirmed()
	if not Input.is_key_pressed(KEY_CONTROL):
		hide()
