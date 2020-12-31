extends "res://resources/texture/texture_layer.gd"

func _init().("Invert") -> void:
	pass


func _get_as_shader_layer() -> Layer:
	var layer := Layer.new()
	layer.code = """
vec4 previous = {previous}(uv);
return vec4(1.0 - previous.r, 1.0 - previous.g, 1.0 - previous.b, 1.0);
"""
	return layer
