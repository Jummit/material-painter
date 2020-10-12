extends "res://resources/blending_texture_layer.gd"

"""
A texture layer that uses a loaded file to generate the result

The file is cached in `cached_image` to avoid loading it every shader update.
"""

var cached_path : String
var cached_image : Texture

export var path := ""

func _init().("file", "File", "texture({texture}, uv)") -> void:
	pass


func get_properties() -> Array:
	return .get_properties() + [Properties.FilePathProperty.new("path")]


func _get_as_shader_layer():
	var layer : BlendingLayer = ._get_as_shader_layer()
	layer.uniform_types.append("sampler2D")
	layer.uniform_names.append("texture")
	
	if cached_path != path:
		var image := Image.new()
		image.load(path)
		cached_image = ImageTexture.new()
		cached_image.create_from_image(image)
		cached_path = path
	
	layer.uniform_values.append(cached_image)
	return layer
