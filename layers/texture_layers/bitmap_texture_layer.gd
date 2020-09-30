extends "res://layers/texture_layer.gd"

"""
A texture layer that uses `Image` data to generate the result

`temp_texture` is used to set a `Texture` directly
to make generating the shader faster.
"""

export var image_data : Image

var temp_texture : Texture

func _init(_name := "Bitmap").("bitmap"):
	name = _name
	image_data = Image.new()
	image_data.create(1024, 1024, false, Image.FORMAT_RGB8)
	image_data.lock()


func _get_as_shader_layer() -> BlendingLayer:
	var layer := ._get_as_shader_layer()
	layer.code = "texture({0}, UV).rgb"
	layer.uniform_types = ["sampler2D"]
	var texture : Texture
	if temp_texture:
		texture = temp_texture
	else:
		texture = ImageTexture.new()
		if image_data.get_data().size() > 0:
			texture.create_from_image(image_data)
	layer.uniform_values = [texture]
	return layer
