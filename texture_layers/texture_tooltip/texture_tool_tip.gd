extends PanelContainer

onready var texture_rect : TextureRect = $VBoxContainer/TextureRect
onready var name_label : Label = $VBoxContainer/Name

const TextureLayer = preload("res://texture_layers/texture_layers.gd").TextureLayer

func setup(texture_layer : TextureLayer) -> void:
	texture_rect.texture = texture_layer.texture
	name_label.text = texture_layer.name
