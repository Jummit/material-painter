extends "res://resources/texture_layer.gd"

export var brightness := 1.0
export var contrast := 1.0

const Properties = preload("res://addons/property_panel/properties.gd")

func _init().("brightness_contrast", "Brightness Contrast") -> void:
	pass


func get_properties() -> Array:
	return [
		Properties.FloatProperty.new("brightness", -3.0, 2.5),
		Properties.FloatProperty.new("contrast", 0.0, 6.0),
	]


func _get_as_shader_layer() -> Layer:
	var layer := Layer.new()
	layer.uniform_types.append("float")
	layer.uniform_names.append("brightness")
	layer.uniform_values.append(brightness)
	layer.uniform_types.append("float")
	layer.uniform_names.append("contrast")
	layer.uniform_values.append(contrast)
	layer.code = """
return {previous}(uv) * {contrast} + vec4(vec3({brightness}), 0.0);
"""
	return layer
