extends "res://texture_layers/texture_layer.gd"

func _init(_name := "Untitled Color Texture"):
	name = _name
	properties.color = Color()


func get_properties() -> Array:
	return .get_properties() + [Properties.ColorProperty.new("color")]


func _get_as_shader_layer() -> Layer:
	var layer := ._get_as_shader_layer()
	layer.code = "{0}"
	layer.uniform_types = ["vec3"]
	layer.uniform_values = [Vector3(properties.color.r, properties.color.g, properties.color.b)]
	return layer
