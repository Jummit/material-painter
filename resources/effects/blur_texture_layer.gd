extends "res://resources/texture_layer.gd"

export var strength := 1.0

const Properties = preload("res://addons/property_panel/properties.gd")

func _init().("blur", "Blur") -> void:
	pass


func get_properties() -> Array:
	return [
		Properties.FloatProperty.new("strength", 0.1, .5),
	]


func _get_as_shader_layer() -> Layer:
	var layer := Layer.new()
	layer.uniform_types.append("float")
	layer.uniform_names.append("strength")
	layer.uniform_values.append(strength)
	layer.code = """
vec2 radius = 0.002 / vec2({strength});
vec4 previous = {previous}(uv);
for(float d = 0.0; d < 6.28318530718; d += 6.28318530718 / float(16)) {
	for(float i = 1.0 / 8.0; i <= 1.0; i += 1.0 / 8.0) {
		previous += {previous}(uv + vec2(cos(d), sin(d)) * radius * i);
	}
}
return previous /= 8.0 * float(16) + 1.0;
"""
	return layer
