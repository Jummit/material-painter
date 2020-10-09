extends PanelContainer

"""
A tooltip for a texture

Used in `TextureLayerTree` to show the result of a `TextureLayer`.
It consists of a name and a big `TextureRect`.
"""

const TextureLayer = preload("res://resources/texture_layer.gd")

onready var texture_rect : TextureRect = $VBoxContainer/TextureRect
onready var name_label : Label = $VBoxContainer/Name

func setup(texture_layer : TextureLayer) -> void:
	texture_rect.texture = texture_layer.result
	name_label.text = texture_layer.name
