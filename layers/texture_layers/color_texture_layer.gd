extends "res://layers/texture_layer.gd"

export var color := Color.white

func _init(_name := "Color").("color"):
	name = _name


func get_properties() -> Array:
	return .get_properties() + [Properties.ColorProperty.new("color")]


func _get_as_shader_layer() -> BlendingLayer:
	var layer := ._get_as_shader_layer()
	layer.code = "{0}"
	layer.uniform_types = ["vec3"]
	layer.uniform_values = [Vector3(color.r, color.g, color.b)]
	return layer
