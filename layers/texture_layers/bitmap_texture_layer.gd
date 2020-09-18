extends "res://layers/texture_layer.gd"

export var image_data : Texture = ImageTexture.new()

func _init(_name := "Untitled Bitmap Texture").("bitmap"):
	name = _name


func _get_as_shader_layer() -> BlendingLayer:
	var layer := ._get_as_shader_layer()
	layer.code = "texture({0}, UV).rgb"
	layer.uniform_types = ["sampler2D"]
	layer.uniform_values = [image_data]
	return layer
