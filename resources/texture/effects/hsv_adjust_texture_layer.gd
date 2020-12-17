extends "res://resources/texture/texture_layer.gd"

export var hue := 1.0
export var saturation := 1.0
export var value := 1.0

const Properties = preload("res://addons/property_panel/properties.gd")

func _init().("hsv_adjust", "HSV Adjust") -> void:
	pass


func get_properties() -> Array:
	return [
		Properties.FloatProperty.new("hue", 0, 1),
		Properties.FloatProperty.new("saturation", -1, 1),
		Properties.FloatProperty.new("value", -1, 1),
	]


func _get_as_shader_layer() -> Layer:
	var layer := Layer.new()
	layer.uniform_types += ["float", "float", "float"]
	layer.uniform_names += ["hue", "saturation", "value"]
	layer.uniform_values += [hue, saturation, value]
	layer.code = """
vec4 previous = {previous}(uv);
vec3 hsv = rgb2hsv(previous.rgb);
hsv.x += {hue};
hsv.y += {saturation};
hsv.z += {value};
return vec4(hsv2rgb(hsv), previous.a);
"""
	return layer
