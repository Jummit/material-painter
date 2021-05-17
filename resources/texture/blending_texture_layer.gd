extends "res://resources/texture/texture_layer.gd"

export var opacity := 1.0
export var blend_mode := "normal"

var code : String

const Properties = preload("res://addons/property_panel/properties.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(_name, _code).(_name):
	code = _code


func get_properties() -> Array:
	return [
			Properties.FloatProperty.new("opacity", 0.0, 1.0, 1.0),
			Properties.EnumProperty.new("blend_mode", Constants.BLEND_MODES),
			]


func _get_as_shader_layer(_context : MaterialGenerationContext) -> Layer:
	return BlendingLayer.new(code, blend_mode, opacity)
