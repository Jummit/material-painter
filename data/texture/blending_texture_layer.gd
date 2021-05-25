extends "res://data/texture/texture_layer.gd"

export var opacity : float
export var blend_mode : String

const Properties = preload("res://addons/property_panel/properties.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(data := {}).(data):
	opacity = data.get("opacity", 1.0)
	blend_mode = data.get("blend_mode", "normal")


func serialize() -> Dictionary:
	var data := .serialize()
	data.opacity = opacity
	data.blend_mode = blend_mode
	return data


func get_properties() -> Array:
	return [
			Properties.FloatProperty.new("opacity", 0.0, 1.0, 1.0),
			Properties.EnumProperty.new("blend_mode", Constants.BLEND_MODES),
			]


func _get_as_shader_layer(_context : MaterialGenerationContext) -> Layer:
	return BlendingLayer.new(get_shader(), blend_mode, opacity)


static func get_shader() -> String:
	return "texture({texture}, uv)"
