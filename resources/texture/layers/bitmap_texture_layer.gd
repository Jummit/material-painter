extends "res://resources/texture/blending_texture_layer.gd"

"""
A texture layer that uses `Image` data to generate the result

`texture` is used to set a `Texture` directly
to make generating the shader faster.
"""

export var image : Image

var texture : Texture

func _init().("Bitmap", "texture({texture}, uv)") -> void:
	# for some reason, NOTIFICATION_POSTINITIALIZE doesn't fire,
	# so use this hack instead
	yield(VisualServer, "frame_post_draw")
	texture = ImageTexture.new()
	if image:
		texture.create_from_image(image)
	else:
		texture.create(1024, 1024, Image.FORMAT_RGB8, ImageTexture.FLAG_FILTER)


func _get_as_shader_layer():
	var layer : BlendingLayer = ._get_as_shader_layer()
	layer.uniform_types.append("sampler2D")
	layer.uniform_names.append("texture")
	layer.uniform_values.append(texture)
	return layer


func save() -> void:
	image = texture.get_data()
