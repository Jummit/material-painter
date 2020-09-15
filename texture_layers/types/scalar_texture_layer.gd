extends "res://texture_layers/texture_layer.gd"

func _init(_name := "Untitled Scalar Texture").("scalar"):
	name = _name
	properties.value = .5


func get_properties() -> Array:
	return .get_properties() + [Properties.FloatProperty.new("value", 0.0, 1.0)]


func _get_as_shader_layer() -> Layer:
	var layer := ._get_as_shader_layer()
	layer.code = "vec3({0}, {0}, {0})"
	layer.uniform_types = ["float"]
	layer.uniform_values = [properties.value]
	return layer
