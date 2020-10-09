extends "res://resources/blending_texture_layer.gd"

"""
A texture layer that uses a loaded file to generate the result

The file is cashed in `cashed_image` to avoid loading it every shader update.
"""

var cashed_path : String
var cashed_image : Texture

export var path := ""

func _init().("file", "texture({texture}, uv)") -> void:
	pass


func get_properties() -> Array:
	return .get_properties() + [Properties.FilePathProperty.new("path")]


func _get_as_shader_layer():
	var layer : BlendingLayer = ._get_as_shader_layer()
	layer.uniform_types.append("sampler2D")
	layer.uniform_names.append("texture")
	
	if cashed_path != path:
		var image := Image.new()
		image.load(path)
		cashed_image = ImageTexture.new()
		cashed_image.create_from_image(image)
		cashed_path = path
	
	layer.uniform_values.append(cashed_image)
	return layer
