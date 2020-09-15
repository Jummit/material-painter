extends "res://texture_layers/texture_layer.gd"

func _init(_name := "Untitled Bitmap Texture").("bitmap"):
	name = _name
	properties.image_path = ""


func get_properties() -> Array:
	return .get_properties() + [Properties.FilePathProperty.new("image_path")]


func _get_as_shader_layer() -> Layer:
	var layer := ._get_as_shader_layer()
	layer.code = "texture({0})"
	layer.uniform_types = ["sampler2D"]
	# todo: load image manually
	layer.uniform_values = [load(properties.image_path)]
	return layer
