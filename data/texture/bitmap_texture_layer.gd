extends "res://data/texture/blending_texture_layer.gd"

"""
A texture layer that uses `Image` data to generate the result

`texture` is used to set a `Texture` directly
to make generating the shader faster.
"""

export var image : Image

var texture : Texture

func _init(data := {}).(data) -> void:
	var new := ImageTexture.new()
	if image:
		new.create_from_image(image)
	else:
		image = Image.new()
		image.create(1024, 1024, false, Image.FORMAT_RGB8)
	new.create_from_image(image, ImageTexture.FLAG_FILTER)
	texture = new


func serialize() -> Dictionary:
	var data := .serialize()
	return data


func get_type() -> String:
	return "bitmap"


func _get_as_shader_layer(context : MaterialGenerationContext) -> Layer:
	var layer : BlendingLayer = ._get_as_shader_layer(context)
	layer.uniform_types.append("sampler2D")
	layer.uniform_names.append("texture")
	layer.uniform_values.append(texture)
	return layer


func save() -> void:
	image = texture.get_data()
