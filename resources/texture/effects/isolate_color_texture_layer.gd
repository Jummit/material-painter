extends "res://resources/texture_layer.gd"

export var color : Color

const Properties = preload("res://addons/property_panel/properties.gd")

func _init().("isolate_color", "Isolate Color") -> void:
	pass


func get_properties() -> Array:
	return [
		Properties.ColorProperty.new("color"),
	]


func _get_as_shader_layer() -> Layer:
	var layer := Layer.new()
	layer.uniform_types.append("vec4")
	layer.uniform_names.append("color")
	layer.uniform_values.append(color)
	layer.code = "return {previous}(uv) == {color} ? vec4(1.0) : vec4(0.0, 0.0, 0.0, 1.0);"
	return layer
