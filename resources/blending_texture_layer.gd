extends "res://resources/texture_layer.gd"

export var opacity := 1.0
export var blend_mode := "normal"

var code : String

const Properties = preload("res://addons/property_panel/properties.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(_type_name, _name, _code).(_type_name, _name):
	code = _code


func get_properties() -> Array:
	return [
			Properties.FloatProperty.new("opacity", 0.0, 1.0),
			Properties.EnumProperty.new("blend_mode", Globals.BLEND_MODES),
			]


func generate_result(result_size : Vector2, keep_viewport := false) -> Texture:
	return yield(LayerBlendViewportManager.blend(
			[_get_as_shader_layer()], result_size,
			get_instance_id() if keep_viewport else -1), "completed")


func _get_as_shader_layer():
	return BlendingLayer.new(code, blend_mode, opacity)
