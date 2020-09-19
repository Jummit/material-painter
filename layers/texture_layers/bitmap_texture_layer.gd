extends "res://layers/texture_layer.gd"

export var image_data : Image

func _init(_name := "Untitled Bitmap Texture").("bitmap"):
	name = _name
	image_data = Image.new()
	image_data.create(1024, 1024, false, Image.FORMAT_RGB8)
	image_data.lock()


func _get_as_shader_layer() -> BlendingLayer:
	var layer := ._get_as_shader_layer()
	layer.code = "texture({0}, UV).rgb"
	layer.uniform_types = ["sampler2D"]
	var texture := ImageTexture.new()
	texture.create_from_image(image_data)
	layer.uniform_values = [texture]
	return layer
