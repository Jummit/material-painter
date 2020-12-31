extends "res://resources/texture/texture_layer.gd"

export var color : Color
export var fuzziness : float

const Properties = preload("res://addons/property_panel/properties.gd")

func _init().("Isolate Color") -> void:
	pass


func get_properties() -> Array:
	return [
		Properties.ColorProperty.new("color"),
		Properties.FloatProperty.new("fuzziness", 0.0, 1.0),
	]


func _get_as_shader_layer() -> Layer:
	var layer := Layer.new()
	layer.uniform_types.append("vec4")
	layer.uniform_names.append("color")
	layer.uniform_values.append(color)
	layer.uniform_types.append("float")
	layer.uniform_names.append("fuzziness")
	layer.uniform_values.append(fuzziness)
	layer.code = "return distance({previous}(uv), {color}) < {fuzziness} ? vec4(1.0) : vec4(0.0, 0.0, 0.0, 1.0);"
	return layer
