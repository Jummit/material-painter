extends "res://resources/blending_texture_layer.gd"

"""
A texture layer that uses `Image` data to generate the result

`temp_texture` is used to set a `Texture` directly
to make generating the shader faster.
"""

export var image_data : Image

var temp_texture : Texture

func _init().("bitmap", "Bitmap", "texture({texture}, uv)") -> void:
	image_data = Image.new()
	image_data.create(1024, 1024, false, Image.FORMAT_RGB8)
	image_data.lock()


func _get_as_shader_layer():
	var layer : BlendingLayer = ._get_as_shader_layer()
	layer.uniform_types.append("sampler2D")
	layer.uniform_names.append("texture")
	var texture : Texture
	if temp_texture:
		texture = temp_texture
	else:
		texture = ImageTexture.new()
		if image_data.get_data().size() > 0:
			texture.create_from_image(image_data)
	layer.uniform_values.append(texture)
	return layer
