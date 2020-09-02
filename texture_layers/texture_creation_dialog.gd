extends ConfirmationDialog

onready var texture_type_list : ItemList = $"TextureTypeList"

const TextureLayer = preload("res://texture_layers/texture_layer.gd")
const BitmapTextureLayer = preload("res://texture_layers/types/bitmap_texture_layer.gd")
const ColorTextureLayer = preload("res://texture_layers/types/color_texture_layer.gd")
const NoiseTextureLayer = preload("res://texture_layers/types/noise_texture_layer.gd")
const PaintTextureLayer = preload("res://texture_layers/types/paint_texture_layer.gd")
const ScalarTextureLayer = preload("res://texture_layers/types/scalar_texture_layer.gd")

signal texture_creation_confirmed(texture_layer)

const CHOICES := [
	BitmapTextureLayer,
	PaintTextureLayer,
	NoiseTextureLayer,
	ColorTextureLayer,
	ScalarTextureLayer,
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
