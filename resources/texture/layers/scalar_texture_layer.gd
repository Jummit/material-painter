extends "res://resources/texture/blending_texture_layer.gd"

"""
A texture layer that uses a float value from 0 to 1 to generate a grayscale result
"""

export var value = .5

func _init().("scalar", "Scalar", "vec4({value}, {value}, {value}, 1.0)") -> void:
	pass


func get_properties() -> Array:
	return .get_properties() + [Properties.FloatProperty.new("value", 0.0, 1.0)]


func _get_as_shader_layer() -> Layer:
	var layer : BlendingLayer = ._get_as_shader_layer()
	layer.uniform_names = ["value"]
	layer.uniform_types = ["float"]
	layer.uniform_values = [value]
	return layer
