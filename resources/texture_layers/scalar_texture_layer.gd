extends "res://resources/texture_layer.gd"

"""
A texture layer that uses a float value from 0 to 1 to generate a grayscale result
"""

export var value = .5

func _init(_name := "Scalar").("scalar"):
	name = _name


func get_properties() -> Array:
	return .get_properties() + [Properties.FloatProperty.new("value", 0.0, 1.0)]


func _get_as_shader_layer() -> BlendingLayer:
	var layer := ._get_as_shader_layer()
	layer.code = "vec3({0}, {0}, {0})"
	layer.uniform_types = ["float"]
	layer.uniform_values = [value]
	return layer
