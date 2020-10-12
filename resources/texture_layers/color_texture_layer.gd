extends "res://resources/blending_texture_layer.gd"

"""
A texture layer that uses a color to generate the result
"""

export var color := Color.white

func _init().("color", "Color", "{color}") -> void:
	pass


func get_properties() -> Array:
	return .get_properties() + [Properties.ColorProperty.new("color")]


func _get_as_shader_layer() -> Layer:
	var layer : BlendingLayer = ._get_as_shader_layer()
	layer.uniform_names = ["color"]
	layer.uniform_types = ["vec4"]
	layer.uniform_values = [color]
	return layer
